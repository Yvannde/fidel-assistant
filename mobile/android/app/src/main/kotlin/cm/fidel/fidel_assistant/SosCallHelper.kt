package cm.fidel.fidel_assistant

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.content.ContextCompat

object SosCallHelper {
    fun placeCall(context: Context, phone: String): String {
        val normalized = phone.filter { it.isDigit() || it == '+' }
        if (normalized.isEmpty()) return "invalid"
        val uri = Uri.parse("tel:$normalized")
        val hasCall = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CALL_PHONE,
        ) == PackageManager.PERMISSION_GRANTED

        return try {
            if (hasCall) {
                val call = Intent(Intent.ACTION_CALL, uri).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(call)
                "call"
            } else {
                val dial = Intent(Intent.ACTION_DIAL, uri).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(dial)
                "dial"
            }
        } catch (_: Exception) {
            try {
                val dial = Intent(Intent.ACTION_DIAL, uri).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(dial)
                "dial"
            } catch (_: Exception) {
                "failed"
            }
        }
    }

    fun hasCallPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CALL_PHONE,
        ) == PackageManager.PERMISSION_GRANTED
    }
}
