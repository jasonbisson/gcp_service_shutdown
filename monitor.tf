resource "google_monitoring_alert_policy" "log-forwarding-function-execution-count" {
project               = var.project_id
    display_name = "log-forwarding-function-execution"

    combiner = "OR"

    conditions {

        display_name = "log forwarding function execution count"

        condition_threshold {

          aggregations {

            alignment_period = "300s" #sample at 5 min intervals

            per_series_aligner = "ALIGN_MEAN"

            cross_series_reducer = "REDUCE_MEAN"

          }

          filter = format("metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND resource.type=\"cloud_function\" AND metric.label.status!=\"ok\" AND resource.labels.function_name=\"%s\"",google_cloudfunctions_function.function.name)
   
          duration = "300s" #Must have messages greater than 0 on the topic for at least 5 mins

          comparison = "COMPARISON_GT"

          threshold_value = 0.01

          trigger {

            count = 1

          }

        }

    }

}