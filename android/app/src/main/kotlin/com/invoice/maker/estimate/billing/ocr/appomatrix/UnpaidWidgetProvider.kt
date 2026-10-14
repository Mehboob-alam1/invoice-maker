package com.invoice.maker.estimate.billing.ocr.appomatrix

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class UnpaidWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            update(context, appWidgetManager, id)
        }
    }

    companion object {
        fun update(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val label = prefs.getString("flutter.widget_unpaid", "0") ?: "0"
            val views = RemoteViews(context.packageName, R.layout.widget_unpaid)
            views.setTextViewText(R.id.widget_amount, label)
            views.setOnClickPendingIntent(R.id.widget_root, openIntent(context, "invoicego://shortcut/home", id))
            views.setOnClickPendingIntent(R.id.widget_add, openIntent(context, "invoicego://shortcut/new", id + 1))
            manager.updateAppWidget(id, views)
        }

        private fun openIntent(context: Context, data: String, requestCode: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                this.data = Uri.parse(data)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            return PendingIntent.getActivity(context, requestCode, intent, flags)
        }
    }
}
