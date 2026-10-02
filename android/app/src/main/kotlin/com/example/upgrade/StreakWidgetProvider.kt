package com.example.upgrade

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

class StreakWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // Tolerate Int / Long / String storage so a type mismatch can never crash the widget.
        val streak = (widgetData.all["streak_count"] as? Number)?.toInt()
            ?: (widgetData.all["streak_count"] as? String)?.toIntOrNull()
            ?: 0
        val studiedDate = widgetData.all["streak_studied_date"] as? String ?: ""
        val c = Calendar.getInstance()
        // Same format as the app's "studied today" marker (no zero padding).
        val today = "${c.get(Calendar.YEAR)}-${c.get(Calendar.MONTH) + 1}-${c.get(Calendar.DAY_OF_MONTH)}"
        val done = studiedDate == today

        appWidgetIds.forEach { id ->
            val v = RemoteViews(context.packageName, R.layout.streak_widget)
            try {
                v.setTextViewText(R.id.widget_count, "$streak ${label(streak)}")
                if (done) {
                    v.setTextViewText(R.id.widget_status, "أحسنت! سلسلتك محفوظة اليوم")
                    v.setViewVisibility(R.id.widget_cta, View.GONE)
                    v.setViewVisibility(R.id.widget_chevron, View.VISIBLE)
                } else {
                    v.setTextViewText(
                        R.id.widget_status,
                        if (streak > 0) "ذاكر اليوم للحفاظ على سلسلتك" else "ابدأ سلسلتك اليوم"
                    )
                    v.setViewVisibility(R.id.widget_cta, View.VISIBLE)
                    v.setViewVisibility(R.id.widget_chevron, View.GONE)
                }
                val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                v.setOnClickPendingIntent(R.id.widget_root, open)
            } catch (e: Exception) {
                android.util.Log.e("StreakWidget", "update failed", e)
            }
            appWidgetManager.updateAppWidget(id, v)
        }
    }

    private fun label(n: Int): String = when {
        n == 1 -> "يوم متتالٍ"
        n == 2 -> "يومان متتاليان"
        n in 3..10 -> "أيام متتالية"
        else -> "يومًا متتاليًا"
    }
}
