package cm.fidel.fidel_assistant

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "cm.fidel.assistant/alarm_health"
    private val checkInChannelName = CheckInActionReceiver.CHANNEL

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FlutterEngineCache.getInstance().put(CheckInActionReceiver.ENGINE_ID, flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStatus" -> result.success(collectStatus())
                    "openExactAlarmSettings" -> {
                        result.success(openExactAlarmSettings())
                    }
                    "openBatteryExemptionSettings" -> {
                        result.success(openBatteryExemptionSettings())
                    }
                    "openFullScreenIntentSettings" -> {
                        result.success(openFullScreenIntentSettings())
                    }
                    "openOemAutostartSettings" -> {
                        result.success(openOemAutostartSettings())
                    }
                    "openAppDetailsSettings" -> {
                        result.success(openAppDetailsSettings())
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, checkInChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        val title = call.argument<String>("title") ?: return@setMethodCallHandler result.error(
                            "arg",
                            "title required",
                            null,
                        )
                        val body = call.argument<String>("body") ?: ""
                        val id = call.argument<Int>("id")
                            ?: CheckInNotificationHelper.DEBUG_NOTIFICATION_ID
                        CheckInNotificationHelper.show(this, title, body, id)
                        result.success(true)
                    }
                    "cancel" -> {
                        val id = call.argument<Int>("id")
                        CheckInNotificationHelper.cancel(this, id)
                        result.success(true)
                    }
                    "scheduleDaily" -> {
                        val title = call.argument<String>("title") ?: return@setMethodCallHandler result.error(
                            "arg",
                            "title required",
                            null,
                        )
                        val body = call.argument<String>("body") ?: ""
                        val hour = call.argument<Int>("hour") ?: 15
                        val minute = call.argument<Int>("minute") ?: 0
                        val skip = call.argument<Boolean>("skipIfSameDayPast") ?: false
                        CheckInNotificationHelper.scheduleDaily(
                            this,
                            title,
                            body,
                            hour,
                            minute,
                            skip,
                        )
                        result.success(true)
                    }
                    "cancelSchedule" -> {
                        CheckInNotificationHelper.cancelSchedule(this)
                        result.success(true)
                    }
                    "consumePendingAction" -> {
                        result.success(CheckInNotificationHelper.consumePendingAction(this))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // App déjà vivante : pousse l’action vers Dart (handler déjà branché).
        val action = intent.getStringExtra(CheckInNotificationHelper.EXTRA_ACTION_ID)
            ?: return
        intent.removeExtra(CheckInNotificationHelper.EXTRA_ACTION_ID)
        MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            checkInChannelName,
        ).invokeMethod("onAction", action)
    }

    private fun collectStatus(): Map<String, Any?> {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notificationsEnabled =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                nm.areNotificationsEnabled()
            } else {
                true
            }

        val exactAlarmOk =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                am.canScheduleExactAlarms()
            } else {
                true
            }

        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val batteryExempt = pm.isIgnoringBatteryOptimizations(packageName)

        val fullScreenOk =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                nm.canUseFullScreenIntent()
            } else {
                true
            }

        return mapOf(
            "notifications" to notificationsEnabled,
            "exactAlarm" to exactAlarmOk,
            "batteryExempt" to batteryExempt,
            "fullScreenIntent" to fullScreenOk,
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "sdkInt" to Build.VERSION.SDK_INT,
            "oemAutostartLikelyNeeded" to oemAutostartLikelyNeeded(),
        )
    }

    private fun oemAutostartLikelyNeeded(): Boolean {
        val m = Build.MANUFACTURER.lowercase()
        val b = Build.BRAND.lowercase()
        val keys = listOf(
            "xiaomi", "redmi", "poco", "huawei", "honor", "oppo", "realme",
            "oneplus", "vivo", "iqoo", "tecno", "infinix", "itel", "transsion",
            "meizu", "asus", "lenovo",
        )
        return keys.any { m.contains(it) || b.contains(it) }
    }

    private fun openExactAlarmSettings(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                startActivity(
                    Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                true
            } else {
                openAppDetailsSettings()
            }
        } catch (_: Exception) {
            openAppDetailsSettings()
        }
    }

    private fun openBatteryExemptionSettings(): Boolean {
        return try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
            true
        } catch (_: Exception) {
            try {
                startActivity(
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                true
            } catch (_: Exception) {
                openAppDetailsSettings()
            }
        }
    }

    private fun openFullScreenIntentSettings(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startActivity(
                    Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                true
            } else {
                openAppDetailsSettings()
            }
        } catch (_: Exception) {
            openAppDetailsSettings()
        }
    }

    private fun openAppDetailsSettings(): Boolean {
        return try {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openOemAutostartSettings(): Boolean {
        val candidates = oemAutostartIntents()
        for (intent in candidates) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    return true
                }
            } catch (_: Exception) {
                // try next
            }
        }
        return openAppDetailsSettings()
    }

    private fun oemAutostartIntents(): List<Intent> {
        val m = Build.MANUFACTURER.lowercase()
        val b = Build.BRAND.lowercase()
        val intents = mutableListOf<Intent>()

        fun add(pkg: String, cls: String) {
            intents.add(
                Intent().setComponent(ComponentName(pkg, cls)),
            )
        }

        when {
            listOf("xiaomi", "redmi", "poco").any { m.contains(it) || b.contains(it) } -> {
                add("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")
                add("com.miui.securitycenter", "com.miui.powercenter.PowerSettings")
            }
            listOf("huawei", "honor").any { m.contains(it) || b.contains(it) } -> {
                add(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
                )
                add(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                )
            }
            listOf("oppo", "realme").any { m.contains(it) || b.contains(it) } -> {
                add(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                )
                add(
                    "com.oplus.safecenter",
                    "com.oplus.safecenter.permission.startup.StartupAppListActivity",
                )
            }
            listOf("oneplus").any { m.contains(it) || b.contains(it) } -> {
                add(
                    "com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
                )
            }
            listOf("vivo", "iqoo").any { m.contains(it) || b.contains(it) } -> {
                add("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")
                add("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")
            }
            listOf("samsung").any { m.contains(it) || b.contains(it) } -> {
                add(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity",
                )
                add(
                    "com.samsung.android.sm",
                    "com.samsung.android.sm.ui.battery.BatteryActivity",
                )
            }
            listOf("tecno", "infinix", "itel", "transsion").any { m.contains(it) || b.contains(it) } -> {
                add(
                    "com.transsion.phonemanager",
                    "com.transsion.phonemanager.module.autostart.AutoStartActivity",
                )
                intents.add(
                    Intent().setComponent(
                        ComponentName(
                            "com.itel.genime",
                            "com.itel.genime.autostart.AutoStartActivity",
                        ),
                    ),
                )
            }
            listOf("asus").any { m.contains(it) || b.contains(it) } -> {
                add(
                    "com.asus.mobilemanager",
                    "com.asus.mobilemanager.autostart.AutoStartActivity",
                )
            }
        }
        return intents
    }
}
