package com.example.monitor_app

import android.app.Notification
import android.content.Intent
import android.os.IBinder
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class RideNotificationListenerService : NotificationListenerService() {
    companion object {
        private const val TAG = "RideNotificationService"
        
        // Pacotes dos aplicativos que queremos monitorar
        private const val UBER_DRIVER_PACKAGE = "com.ubercab.driver"
        private const val UBER_DRIVER_PACKAGE_ALT = "com.ubercab.driver.development"
        private const val NINETY_NINE_PACKAGE = "com.taxis99"
        private const val NINETY_NINE_PACKAGE_ALT = "com.taxis99.driver"
        
        // Ação enviada para o Flutter quando uma notificação relevante for detectada
        const val ACTION_RIDE_NOTIFICATION = "com.example.monitor_app.ACTION_RIDE_NOTIFICATION"
        const val EXTRA_APP_NAME = "app_name"
        const val EXTRA_NOTIFICATION_TITLE = "notification_title"
        const val EXTRA_NOTIFICATION_TEXT = "notification_text"
        
        // Esses são títulos/textos comuns para notificações de oferta de corrida
        // Podemos refinar isso com base em mais exemplos reais
        private val UBER_RIDE_TITLE_KEYWORDS = arrayOf("Nova viagem", "Nova corrida", "Solicitação de viagem")
        private val NINETY_NINE_RIDE_TITLE_KEYWORDS = arrayOf("Nova corrida", "Novo chamado", "Chamado disponível")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        
        // Verificar se é uma notificação dos apps que estamos monitorando
        if (packageName == UBER_DRIVER_PACKAGE || packageName == UBER_DRIVER_PACKAGE_ALT ||
            packageName == NINETY_NINE_PACKAGE || packageName == NINETY_NINE_PACKAGE_ALT) {
            
            // Extrair informações da notificação
            val notification = sbn.notification
            val extras = notification.extras
            val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            
            // Verificar se é uma notificação de oferta de corrida
            if (isRideOfferNotification(packageName, title, text)) {
                Log.d(TAG, "Notificação de corrida detectada: $title - $text")
                
                // Determinar qual é o app
                val appName = when (packageName) {
                    UBER_DRIVER_PACKAGE, UBER_DRIVER_PACKAGE_ALT -> "Uber"
                    NINETY_NINE_PACKAGE, NINETY_NINE_PACKAGE_ALT -> "99"
                    else -> "Desconhecido"
                }
                
                // Enviar broadcast para o Flutter
                val intent = Intent(ACTION_RIDE_NOTIFICATION)
                intent.putExtra(EXTRA_APP_NAME, appName)
                intent.putExtra(EXTRA_NOTIFICATION_TITLE, title)
                intent.putExtra(EXTRA_NOTIFICATION_TEXT, text)
                sendBroadcast(intent)
                
                // Iniciar o serviço para capturar a tela
                val captureIntent = Intent(this, MainActivity::class.java)
                captureIntent.action = MainActivity.ACTION_CAPTURE_SCREEN
                captureIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(captureIntent)
            }
        }
    }

    private fun isRideOfferNotification(packageName: String, title: String, text: String): Boolean {
        // Verificar se o título da notificação contém keywords específicas baseadas no app
        return when {
            packageName == UBER_DRIVER_PACKAGE || packageName == UBER_DRIVER_PACKAGE_ALT -> 
                UBER_RIDE_TITLE_KEYWORDS.any { title.contains(it, ignoreCase = true) }
            
            packageName == NINETY_NINE_PACKAGE || packageName == NINETY_NINE_PACKAGE_ALT -> 
                NINETY_NINE_RIDE_TITLE_KEYWORDS.any { title.contains(it, ignoreCase = true) }
            
            else -> false
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Implementar se precisarmos reagir quando a notificação é removida
    }
}
