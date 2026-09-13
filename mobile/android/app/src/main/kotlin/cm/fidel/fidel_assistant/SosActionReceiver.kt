package cm.fidel.fidel_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class SosActionReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL = "cm.fidel.assistant/sos"
        const val ENGINE_ID = "fidel_main_engine"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.getStringExtra(SosNotificationHelper.EXTRA_ACTION)
            ?: intent?.action
            ?: return
        SosNotificationHelper.stashAction(context, action)

        if (action == SosNotificationHelper.ACTION_CANCEL_COUNTDOWN) {
            val stop = Intent(context, SosCountdownService::class.java).apply {
                this.action = SosCountdownService.ACTION_STOP
            }
            context.startService(stop)
        }

        val engine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        if (engine != null) {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("onAction", action)
        } else {
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(SosNotificationHelper.EXTRA_ACTION, action)
            }
            context.startActivity(launch)
        }
    }
}
