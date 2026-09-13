package cm.fidel.fidel_assistant

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/** Notif persistante SOS (visible lock screen) + pending actions. */
object SosNotificationHelper {
    const val CHANNEL_ID = "fidel_sos_trigger"
    const val NOTIFICATION_ID = 91001600
    const val ACTION_TRIGGER = "sos_trigger"
    const val ACTION_CANCEL_COUNTDOWN = "sos_cancel_countdown"
    const val EXTRA_ACTION = "sos_action"
    const val PREFS = "fidel_sos_notif"
    const val KEY_PENDING = "pending_action"
    const val CHANNEL_NAME = "SOS Fidel"
    const val CHANNEL_DESC = "Bouton SOS accessible même écran verrouillé"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH).apply {
                description = CHANNEL_DESC
                setShowBadge(true)
                enableVibration(true)
            },
        )
    }

    fun showPersistent(context: Context, title: String, body: String) {
        ensureChannel(context)
        val open = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("sos_open", true)
            },
            pendingFlags(),
        )
        val trigger = PendingIntent.getBroadcast(
            context,
            NOTIFICATION_ID + 1,
            Intent(context, SosActionReceiver::class.java).apply {
                action = ACTION_TRIGGER
                putExtra(EXTRA_ACTION, ACTION_TRIGGER)
            },
            pendingFlags(),
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(open)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(0, "SOS", trigger)
            .build()
        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }

    fun hidePersistent(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    fun stashAction(context: Context, action: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PENDING, action)
            .apply()
    }

    fun consumePendingAction(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val action = prefs.getString(KEY_PENDING, null) ?: return null
        prefs.edit().remove(KEY_PENDING).apply()
        return action
    }

    private fun pendingFlags(): Int {
        return PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
    }
}
