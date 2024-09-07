import requests
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

  for provider in providers:
    vehicle_status_url = provider["url"]
    response = requests.get(vehicle_status_url)
    response.raise_for_status()
    vehicle_data = response.json()

    vehicles = vehicle_data["data"]["vehicles"]
    total_vehicles = len(vehicles)
    available_vehicles = [vehicle for vehicle in vehicles if not vehicle["is_disabled"] and not vehicle["is_reserved"]]
    total_available_vehicles = len(available_vehicles)

    print(f"{provider['name']}:")
    print(f"  Total Vehicles: {total_vehicles}")
    print(f"  Available Vehicles: {total_available_vehicles}")
    print()
if __name__ == "__main__":
  fetch_and_process_data(None,None)