import requests
import boto3
import os

def fetch_and_process_data(event, context):
  providers = []

  for prefix in ["PROVIDER_1_", "PROVIDER_2_", "PROVIDER_3_"]:
    url_var = prefix + "URL"
    name_var = prefix + "NAME"
    if url := os.getenv(url_var):
      name = os.getenv(name_var, f"Provider {prefix[:-1]}")
      providers.append({"url": url, "name": name})

  print(providers)
  cw = boto3.client('cloudwatch')
  
  for provider in providers:
    vehicle_status_url = provider["url"]
    try:
      response = requests.get(vehicle_status_url, timeout=10)  # Added timeout for request
      response.raise_for_status()
      vehicle_fetch_data = response.json()

      vehicles = vehicle_fetch_data["data"]["vehicles"]
      total_vehicles = len(vehicles)
      available_vehicles = [vehicle for vehicle in vehicles if not vehicle["is_disabled"] and not vehicle["is_reserved"]]
      total_available_vehicles = len(available_vehicles)
    
    except (requests.exceptions.RequestException, KeyError) as e:
      print(f"Error collecting data for {provider['name']}: {e}")
      total_vehicles = 0
      total_available_vehicles = 0

    cw.put_metric_data(
      Namespace='GBFSMonitoring',
      MetricData=[
        {
          'MetricName': 'TotalVehicles',
          'Value': total_vehicles,
          'Unit': 'Count',
          'Dimensions': [
            {'Name': 'ProviderName', 'Value': provider['name']}
          ]
        },
        {
          'MetricName': 'AvailableVehicles',
          'Value': total_available_vehicles,
          'Unit': 'Count',
          'Dimensions': [
            {'Name': 'ProviderName', 'Value': provider['name']}
          ]
        }
      ]
    )

    print(f"{provider['name']}:")
    print(f"  Total Vehicles: {total_vehicles}")
    print(f"  Available Vehicles: {total_available_vehicles}")
    print()

if __name__ == "__main__":
  fetch_and_process_data(None, None)
