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
        // Last server-confirmed streak, kept as-is when a refresh fails.
        val streak = widgetData.getInt("streak_count", 0)
        val studiedDate = widgetData.getString("streak_studied_date", "")
        val c = Calendar.getInstance()
        // Same format as the app's "studied today" marker (no zero padding).
        val today = "${c.get(Calendar.YEAR)}-${c.get(Calendar.MONTH) + 1}-${c.get(Calendar.DAY_OF_MONTH)}"
        val done = studiedDate == today

        val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)

        appWidgetIds.forEach { id ->
            val v = RemoteViews(context.packageName, R.layout.streak_widget)
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
            v.setOnClickPendingIntent(R.id.widget_root, open)
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
