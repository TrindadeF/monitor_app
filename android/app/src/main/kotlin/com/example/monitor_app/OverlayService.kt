package com.example.monitor_app

import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.widget.FrameLayout

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isOverlayShown = false

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_SHOW_OVERLAY) {
            val price = intent.getDoubleExtra(EXTRA_PRICE, 0.0)
            val pricePerKm = intent.getDoubleExtra(EXTRA_PRICE_PER_KM, 0.0)
            val pricePerMinute = intent.getDoubleExtra(EXTRA_PRICE_PER_MINUTE, 0.0)
            val pricePerSegment = intent.getDoubleExtra(EXTRA_PRICE_PER_SEGMENT, 0.0)
            
            showOverlay(price, pricePerKm, pricePerMinute, pricePerSegment)
        } else if (intent?.action == ACTION_HIDE_OVERLAY) {
            hideOverlay()
        }
        
        return START_NOT_STICKY
    }

    private fun showOverlay(price: Double, pricePerKm: Double, pricePerMinute: Double, pricePerSegment: Double) {
        if (isOverlayShown) {
            hideOverlay()
        }
        
        // Criar layout para o overlay
        val inflater = getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = FrameLayout(this).apply {
            // Configurar o layout principal
            val view = TextView(context).apply {
                text = String.format("R$%.2f | R$%.2f/km | R$%.2f/min | R$%.2f/seg", 
                                     price, pricePerKm, pricePerMinute, pricePerSegment)
                setBackgroundColor(Color.parseColor("#80000000")) // Fundo preto semi-transparente
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setPadding(20, 10, 20, 10)
                textSize = 16f
            }
            addView(view)
            setOnClickListener {
                // Clicar no overlay o remove
                hideOverlay()
            }
        }

        // Definir os parâmetros do layout
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY 
            else 
                WindowManager.LayoutParams.TYPE_SYSTEM_ALERT,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        
        // Posicionar no topo da tela
        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = 100 // Afastar um pouco do topo
        
        // Adicionar a view à janela
        try {
            windowManager?.addView(overlayView, params)
            isOverlayShown = true
            
            // Configurar um temporizador para remover o overlay após alguns segundos
            overlayView?.postDelayed({ hideOverlay() }, OVERLAY_DURATION)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun hideOverlay() {
        if (isOverlayShown && overlayView != null) {
            try {
                windowManager?.removeView(overlayView)
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                overlayView = null
                isOverlayShown = false
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
    }

    companion object {
        const val ACTION_SHOW_OVERLAY = "com.example.monitor_app.ACTION_SHOW_OVERLAY"
        const val ACTION_HIDE_OVERLAY = "com.example.monitor_app.ACTION_HIDE_OVERLAY"
        const val EXTRA_PRICE = "price"
        const val EXTRA_PRICE_PER_KM = "price_per_km"
        const val EXTRA_PRICE_PER_MINUTE = "price_per_minute"
        const val EXTRA_PRICE_PER_SEGMENT = "price_per_segment"
        private const val OVERLAY_DURATION = 8000L // 8 segundos
    }
}
