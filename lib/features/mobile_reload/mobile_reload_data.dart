class NetworkProvider {
  final String id;
  final String name;
  final String logoUrl;
  final String colorHex;

  const NetworkProvider({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.colorHex,
  });
}

class DataPackage {
  final String id;
  final String name;
  final String description;
  final double price;
  final String providerId;
  final String type; // 'Data', 'Voice', 'Combo'

  const DataPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.providerId,
    required this.type,
  });
}

const List<NetworkProvider> networkProviders = [
  NetworkProvider(
    id: 'dialog',
    name: 'Dialog',
    logoUrl: 'assets/images/dialog_logo.png',
    colorHex: 'ED1C24',
  ),
  NetworkProvider(
    id: 'mobitel',
    name: 'Mobitel',
    logoUrl: 'assets/images/mobitel_logo.png',
    colorHex: '00A650',
  ),
  NetworkProvider(
    id: 'airtel',
    name: 'Airtel',
    logoUrl: 'assets/images/airtel_logo.png',
    colorHex: 'FF0000',
  ),
  NetworkProvider(
    id: 'hutch',
    name: 'Hutch',
    logoUrl: 'assets/images/hutch_logo.png',
    colorHex: 'F7941D',
  ),
];

const List<DataPackage> dummyDataPackages = [
  // Dialog Packages
  DataPackage(
      id: 'd1',
      name: 'Fun Blaster 98',
      description: 'Unlimited Facebook, WhatsApp & YouTube for 7 Days',
      price: 98,
      providerId: 'dialog',
      type: 'Data'),
  DataPackage(
      id: 'd2',
      name: 'Work & Learn 498',
      description: '30GB Anytime + 30GB Zoom/Teams (30 Days)',
      price: 498,
      providerId: 'dialog',
      type: 'Data'),
  DataPackage(
      id: 'd3',
      name: 'Triple Blaster 345',
      description: '1000 D2D Mins, 1000 D2D SMS, 1.5GB Data (30 Days)',
      price: 345,
      providerId: 'dialog',
      type: 'Combo'),
  DataPackage(
      id: 'd4',
      name: 'Anytime 199',
      description: '2GB Anytime Data (30 Days)',
      price: 199,
      providerId: 'dialog',
      type: 'Data'),

  // Mobitel Packages
  DataPackage(
      id: 'm1',
      name: 'Triple Buddy 339',
      description: 'Facebook, WhatsApp, YouTube Free (30 Days)',
      price: 339,
      providerId: 'mobitel',
      type: 'Combo'),
  DataPackage(
      id: 'm2',
      name: 'Non-Stop Lokka 289',
      description: 'Unlimited Social Media (30 Days)',
      price: 289,
      providerId: 'mobitel',
      type: 'Data'),
  DataPackage(
      id: 'm3',
      name: 'Anytime 199',
      description: '2GB Anytime (21 Days)',
      price: 199,
      providerId: 'mobitel',
      type: 'Data'),
  DataPackage(
      id: 'm4',
      name: 'Voice 245',
      description: 'Unlimited M2M calls (30 Days)',
      price: 245,
      providerId: 'mobitel',
      type: 'Voice'),

  // Airtel Packages
  DataPackage(
      id: 'a1',
      name: 'Freedom 888',
      description: 'Unlimited Airtel calls, 30GB Data (30 Days)',
      price: 888,
      providerId: 'airtel',
      type: 'Combo'),
  DataPackage(
      id: 'a2',
      name: 'Data 199',
      description: '3GB Anytime Data (30 Days)',
      price: 199,
      providerId: 'airtel',
      type: 'Data'),

  // Hutch Packages
  DataPackage(
      id: 'h1',
      name: 'CliQ 399',
      description: 'Unlimited Data for 30 Days (3G/4G)',
      price: 399,
      providerId: 'hutch',
      type: 'Data'),
  DataPackage(
      id: 'h2',
      name: 'Voice 149',
      description: 'Unlimited Hutch Calls (30 Days)',
      price: 149,
      providerId: 'hutch',
      type: 'Voice'),
];
