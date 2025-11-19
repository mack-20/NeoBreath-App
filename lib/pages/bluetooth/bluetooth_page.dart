import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';
import '../../services/bluetooth_service.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _bluetoothEnabled = false;
  List<BluetoothDevice> _devices = [];
  String _statusMessage = 'Initializing...';

  static const String TARGET_DEVICE_NAME = "NeoBreath Hub";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Step 1: Request Bluetooth permissions
    setState(() {
      _statusMessage = 'Requesting permissions...';
    });

    final permissionsGranted = await _bluetoothService.ensureBluetoothPermissions();
    
    if (!permissionsGranted) {
      setState(() {
        _statusMessage = 'Bluetooth permissions denied';
      });
      _showErrorDialog('Permissions Required', 
        'Please grant Bluetooth permissions in app settings to continue.');
      return;
    }

    // Step 2: Check if Bluetooth is supported
    final isSupported = await _bluetoothService.isBluetoothSupported();
    
    if (!isSupported) {
      setState(() {
        _statusMessage = 'Bluetooth not supported on this device';
      });
      _showErrorDialog('Bluetooth Not Supported', 
        'Your device does not support Bluetooth.');
      return;
    }

    // Step 3: Check if Bluetooth is enabled
    final isEnabled = await _bluetoothService.isBluetoothEnabled();
    
    setState(() {
      _bluetoothEnabled = isEnabled;
    });

    if (!isEnabled) {
      setState(() {
        _statusMessage = 'Please enable Bluetooth';
      });
      _showEnableBluetoothDialog();
      return;
    }

    // Step 4: Start scanning
    await _startScanning();
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for devices...';
      _devices.clear();
    });

    try {
      // Setup listeners for Bluetooth events
      _bluetoothService.setupListeners();

      // First, get paired devices
      final pairedDevices = await _bluetoothService.getPairedDevices();
      
      setState(() {
        _devices = pairedDevices;
        _statusMessage = pairedDevices.isEmpty 
            ? 'No paired devices found. Discovering...' 
            : 'Found ${pairedDevices.length} paired device(s)';
      });

      // Start discovery for unpaired devices
      final discoveryStarted = await _bluetoothService.startDiscovery();
      
      if (!discoveryStarted) {
        setState(() {
          _statusMessage = 'Failed to start device discovery';
        });
      }

      // Wait a bit for discovery to find devices
      await Future.delayed(Duration(seconds: 5));

      // Stop discovery after timeout
      await _bluetoothService.stopDiscovery();

      setState(() {
        _isScanning = false;
        if (_devices.isEmpty) {
          _statusMessage = 'No devices found';
        } else {
          _statusMessage = 'Tap on "$TARGET_DEVICE_NAME" to connect';
        }
      });

    } catch (e) {
      print('Error during scanning: $e');
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan failed: $e';
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to ${device.name}...';
    });

    try {
      final connected = await _bluetoothService.connectToDevice(device.address);

      if (connected) {
        // Connection successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${device.name}'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Wait a moment to show the success message
          await Future.delayed(Duration(milliseconds: 500));

          // Return true to indicate successful connection
          Navigator.pop(context, true);
        }
      } else {
        // Connection failed
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Connection failed. Try again.';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect to ${device.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Connection error: $e');
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Connection error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEnableBluetoothDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Enable Bluetooth'),
        content: Text('Please enable Bluetooth in your device settings and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Close Bluetooth page
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              // Re-check after user presumably enabled it
              await _initialize();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B6B),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Close Bluetooth page
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.stopDiscovery();
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isConnecting ? null : () => Navigator.pop(context, false),
        ),
        title: Text(
          'Connect to Device',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isScanning && !_isConnecting)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.black87),
              onPressed: _startScanning,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isConnecting
          ? _buildConnectingState()
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _devices.isEmpty
                      ? _buildEmptyState()
                      : _buildDeviceList(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              if (_isScanning) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6B6B),
                    ),
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _isScanning ? 'Searching for devices...' : _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8A8A8A),
            ),
          ),
          if (!_isScanning) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startScanning,
              icon: Icon(Icons.refresh),
              label: Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final deviceName = device.name ?? 'Unknown Device';
        final isTargetDevice = deviceName == TARGET_DEVICE_NAME;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isTargetDevice
                ? BorderSide(color: Color(0xFFFF6B6B), width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isTargetDevice
                    ? Color(0xFFFFE5E5)
                    : Color(0xFFE2EDFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth,
                color: isTargetDevice
                    ? Color(0xFFFF6B6B)
                    : Color(0xFF1B86ED),
              ),
            ),
            title: Text(
              deviceName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  device.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                if (isTargetDevice) ...[
                  SizedBox(height: 4),
                  Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _connectToDevice(device),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTargetDevice
                    ? Color(0xFFFF6B6B)
                    : Color(0xFF1B86ED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Connect'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFFF6B6B),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF48576B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8A8A8A),
            ),
          ),
        ],
      ),
    );
  }
}