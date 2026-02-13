package com.mrahmiakpinar.sparkio

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class SparkioHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateAllWidgets(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_HOME_WIDGET_UPDATE) {
            updateAllWidgets(context)
        }
    }

    companion object {
        const val ACTION_HOME_WIDGET_UPDATE =
            "com.mrahmiakpinar.sparkio.ACTION_HOME_WIDGET_UPDATE"

        private const val PREFS_NAME = "sparkio_home_widget_v1"
        private const val KEY_REMAINING_TASKS = "remaining_tasks"
        private const val KEY_TIMER_ACTIVE = "timer_active"
        private const val KEY_TIMER_FINISHED = "timer_finished"
        private const val KEY_TIMER_TASK_TITLE = "timer_task_title"
        private const val KEY_TIMER_REMAINING_SEC = "timer_remaining_sec"

        fun saveSnapshot(
            context: Context,
            remainingTasks: Int,
            timerActive: Boolean,
            timerFinished: Boolean,
            timerTaskTitle: String,
            timerRemainingSec: Int
        ) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putInt(KEY_REMAINING_TASKS, remainingTasks.coerceAtLeast(0))
                .putBoolean(KEY_TIMER_ACTIVE, timerActive)
                .putBoolean(KEY_TIMER_FINISHED, timerFinished)
                .putString(KEY_TIMER_TASK_TITLE, timerTaskTitle)
                .putInt(KEY_TIMER_REMAINING_SEC, timerRemainingSec.coerceAtLeast(0))
                .apply()
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, SparkioHomeWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(componentName)
            if (ids.isEmpty()) return
            for (id in ids) {
                updateSingleWidget(context, appWidgetManager, id)
            }
        }

        private fun updateSingleWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val remainingTasks = prefs.getInt(KEY_REMAINING_TASKS, 0).coerceAtLeast(0)
            val timerActive = prefs.getBoolean(KEY_TIMER_ACTIVE, false)
            val timerFinished = prefs.getBoolean(KEY_TIMER_FINISHED, false)
            val timerTaskTitle = prefs.getString(KEY_TIMER_TASK_TITLE, "") ?: ""
            val timerRemainingSec = prefs.getInt(KEY_TIMER_REMAINING_SEC, 0).coerceAtLeast(0)

            val views = RemoteViews(context.packageName, R.layout.sparkio_home_widget)
            views.setTextViewText(
                R.id.widget_remaining_value,
                if (remainingTasks == 1) "1 task left" else "$remainingTasks tasks left"
            )

            if (!timerActive) {
                views.setTextViewText(R.id.widget_timer_title, "Active timer")
                views.setTextViewText(R.id.widget_timer_value, "No active timer")
            } else {
                views.setTextViewText(
                    R.id.widget_timer_title,
                    if (timerTaskTitle.isBlank()) "Active timer" else timerTaskTitle
                )
                views.setTextViewText(
                    R.id.widget_timer_value,
                    if (timerFinished) "Time is up" else formatDuration(timerRemainingSec)
                )
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            } else {
                views.setViewVisibility(R.id.widget_root, View.VISIBLE)
            }

            manager.updateAppWidget(appWidgetId, views)
        }

        private fun formatDuration(totalSeconds: Int): String {
            val safe = totalSeconds.coerceAtLeast(0)
            val minutes = safe / 60
            val seconds = safe % 60
            return String.format("%02d:%02d", minutes, seconds)
        }
    }
}
