package cm.fidel.fidel_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Déclenche la notif check-in planifiée (15 h). */
class CheckInAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(
            CheckInNotificationHelper.PREFS,
            Context.MODE_PRIVATE,
        )
        val title = intent.getStringExtra("title")
            ?: prefs.getString("title", null)
            ?: "Comment tu te sens aujourd’hui ?"
        val body = intent.getStringExtra("body")
            ?: prefs.getString("body", null)
            ?: "Un geste, quatre choix — ça aide à suivre ton suivi."
        CheckInNotificationHelper.show(
            context,
            title,
            body,
            CheckInNotificationHelper.NOTIFICATION_ID,
        )
        // Replanifie le lendemain (récurrence manuelle).
        CheckInNotificationHelper.scheduleDaily(
            context,
            title,
            body,
            hour = 15,
            minute = 0,
            skipIfSameDayPast = true,
        )
    }
}
