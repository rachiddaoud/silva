package com.rachid.silva

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quote).apply {
                val quoteText = widgetData.getString("quote_text", "No quote yet today.")
                setTextViewText(R.id.widget_quote_text, quoteText)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
