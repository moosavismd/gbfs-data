locals {
  gbfs_dashboard_widgets = {
    widgets = [
      {
        type = "metric",
        properties = {
          "metrics" : [
            ["GBFSMonitoring", "TotalVehicles", "ProviderName", "Almere", { "region" : "us-east-1" }],
            [".", "AvailableVehicles", ".", ".", { "region" : "us-east-1" }],
            ["...", "Amersfoort", { "region" : "us-east-1" }],
            [".", "TotalVehicles", ".", ".", { "region" : "us-east-1" }],
            [".", "AvailableVehicles", ".", "Amsterdam", { "region" : "us-east-1" }],
            [".", "TotalVehicles", ".", ".", { "region" : "us-east-1" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "us-east-1",
          "period" : 60,
          "stat" : "Average"
        }
      }
    ]
  }
}