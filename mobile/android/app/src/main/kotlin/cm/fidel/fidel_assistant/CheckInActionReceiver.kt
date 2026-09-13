package cm.fidel.fidel_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Clic sur une des 4 icônes mood de la notif custom.
 */
class CheckInActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val actionId = intent.getStringExtra(CheckInNotificationHelper.EXTRA_ACTION_ID) ?: return
        val notificationId = intent.getIntExtra(
            CheckInNotificationHelper.EXTRA_NOTIFICATION_ID,
            CheckInNotificationHelper.DEBUG_NOTIFICATION_ID,
        )
        CheckInNotificationHelper.cancel(context, notificationId)
        CheckInNotificationHelper.storePendingAction(context, actionId)

        val engine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        if (engine != null) {
            MethodChannel(
                engine.dartExecutor.binaryMessenger,
                CHANNEL,
            ).invokeMethod("onAction", actionId)
        } else {
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(CheckInNotificationHelper.EXTRA_ACTION_ID, actionId)
            }
            context.startActivity(launch)
        }
    }

    companion object {
        const val ENGINE_ID = "fidel_main_engine"
        const val CHANNEL = "cm.fidel.assistant/check_in_notif"
    }
}
