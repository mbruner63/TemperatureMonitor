//---------------------------------------------------------------------------

// Temperature Monitor
// Martin Bruner 4/18/20
// Example App to demonstrate connecting with a BLE temperature
// device, recording its readings, and posting the data to a
// Kinvey Cloud DataBase.
// This code is adapted from a Embarcadero Rad Studio Heart Rate
// Monitor Project


//---------------------------------------------------------------------------

unit UTemperatureForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Ani, FMX.StdCtrls, System.Bluetooth, FMX.Layouts,
  FMX.Memo, FMX.Controls.Presentation, FMX.Edit, FMX.Objects, IPPeerClient, IPPeerServer,
  System.Tether.Manager, System.Bluetooth.Components, FMX.ListBox, FMX.ScrollBox, System.Permissions,
  System.Diagnostics, FMX.DialogService,
  System.DateUtils,
  System.TimeSpan,  System.ImageList, FMX.ImgList,
  FMXTee.Series, FMXTee.Engine, FMXTee.Procs,
  FMXTee.Chart, System.IOUtils, System.JSON, uBackend,
  System.Sensors,
{$IFDEF IOS}
  iOSapi.UIKit,
{$ENDIF}
{$IFDEF ANDROID}
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.App,
  Androidapi.Helpers, FMX.Platform.Android, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Net, Androidapi.JNI.Os, Androidapi.JNIBridge,

{$ENDIF}
  FMX.Platform;

type

  TSensorContactStatus = (NonSupported, NonDetected, Detected);

  THRMFlags = record
    HRValue16bits: boolean;
    SensorContactStatus: TSensorContactStatus;
    EnergyExpended: boolean;
    RRInterval: boolean;
  end;

  TfrmTemperatureMonitor = class(TForm)
    BluetoothLE1: TBluetoothLE;
    pnlLog: TPanel;
    LogList: TListBox;
    ListBoxGroupHeader1: TListBoxGroupHeader;
    ListBoxItem1: TListBoxItem;
    Memo1: TMemo;
    pnlMain: TPanel;
    MainList: TListBox;
    DeviceScan: TListBoxItem;
    lblDevice: TLabel;
    btnScan: TButton;
    BPM: TListBoxItem;
    lblBPM: TLabel;
    Image: TListBoxItem;
    Location: TListBoxItem;
    lblBodyLocation: TLabel;
    Status: TListBoxItem;
    lblContactStatus: TLabel;
    Monitoring: TListBoxItem;
    btnMonitorize: TButton;
    ToolBar1: TToolBar;
    Label1: TLabel;
    procedure btnScanClick(Sender: TObject);
    procedure btnMonitorizeClick(Sender: TObject);
    procedure btConnectClick(Sender: TObject);
    procedure BluetoothLE1EndDiscoverDevices(const Sender: TObject; const ADeviceList: TBluetoothLEDeviceList);
    procedure BluetoothLE1DescriptorRead(const Sender: TObject; const ADescriptor: TBluetoothGattDescriptor;
      AGattStatus: TBluetoothGattStatus);
    procedure BluetoothLE1CharacteristicRead(const Sender: TObject; const ACharacteristic: TBluetoothGattCharacteristic;
      AGattStatus: TBluetoothGattStatus);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    //FBluetoothLE: TBluetoothLE;
    //FBLEManager: TBluetoothLEManager;
    FBLEDevice: TBluetoothLEDevice;

    FHRGattService: TBluetoothGattService;
    FHRMeasurementGattCharact: TBluetoothGattCharacteristic;
    FBodySensorLocationGattCharact: TBluetoothGattCharacteristic;
   
    procedure GetServiceAndCharacteristics;

    procedure ManageCharacteristicData(const ACharacteristic: TBluetoothGattCharacteristic);
    procedure DisplayTemperatureMeasurementData(Data: TBytes);
    procedure DisplayBodySensorLocationData(Index: Byte);

    function GetFlags(Data: Byte): THRMFlags;
    procedure EnableTemperatureMonitorize(Enabled: boolean);
    procedure ReadBodySensorLocation;

    procedure ClearData;
    procedure DoScan;
     procedure DisplayRationale(Sender: TObject;
      const APermissions: TArray<string>; const APostRationaleProc: TProc);
    procedure RequestPermissionsResult(Sender: TObject;
      const APermissions: TArray<string>;
      const AGrantResults: TArray<TPermissionStatus>);

  public
    { Public declarations }
  end;




const
  TempDeviceName = 'Temperature Monitor';
  ServiceUUID = '';
  CharactUUID = '';

  TEMPSERVICE: TBluetoothUUID = '{00001809-0000-1000-8000-00805F9B34FB}';
  HRMEASUREMENT_CHARACTERISTIC: TBluetoothUUID  = '{00002A1C-0000-1000-8000-00805F9B34FB}';
  BODY_SENSOR_LOCATION_CHARACTERISTIC: TBluetoothUUID  = '{00002A38-0000-1000-8000-00805F9B34FB}';

  //TEMP_SERVICE: TBluetoothUUID = '{0000180D-0000-1000-8000-00805F9B34FB}';

  BodySensorLocations : array[0..6] of string = ('Other', 'Chest', 'Wrist', 'Finger', 'Hand', 'Ear Lobe', 'Foot');

  HR_VALUE_FORMAT_MASK = $1;
  SENSOR_CONTACT_STATUS_MASK = $6;
  ENERGY_EXPANDED_STATUS_MASK = $8;
  RR_INTERVAL_MASK = $10;



var
  frmTemperatureMonitor: TfrmTemperatureMonitor;
  FLocationPermission: string;

implementation

{$R *.fmx}

function BytesToString(const B: TBytes): string;
var
  I: Integer;
begin
  if Length(B) > 0 then
  begin
    Result := Format('%0.2X', [B[0]]);
    for I := 1 to High(B) do
      Result := Result + Format(' %0.2X', [B[I]]);
  end
  else
    Result := '';
end;

function TfrmTemperatureMonitor.GetFlags(Data: Byte): THRMFlags;
var
  LValue: Byte;
begin
  Result.HRValue16bits := (Data and HR_VALUE_FORMAT_MASK) = 1;
  LValue := (Data and SENSOR_CONTACT_STATUS_MASK) shr 1;
  case LValue of
    2: Result.SensorContactStatus := NonDetected;
    3: Result.SensorContactStatus := Detected;
    else
      Result.SensorContactStatus := NonSupported;
  end;
  Result.EnergyExpended := ((Data and ENERGY_EXPANDED_STATUS_MASK) shr 3) = 1;
  Result.RRInterval := ((Data and RR_INTERVAL_MASK) shr 4) = 1;
end;

procedure TfrmTemperatureMonitor.EnableTemperatureMonitorize(Enabled: boolean);
begin
  if FHRMeasurementGattCharact <> nil then
  begin
{$IFDEF MSWINDOWS}
{
    LDescriptor := FHRMeasurementGattCharact.Descriptors[0];
    LDescriptor.Notification := Enabled;
    FBluetoothLE.WriteDescriptor(FBLEDevice, LDescriptor);
    }
{$ENDIF}
    if Enabled then
    begin
      BluetoothLE1.SubscribeToCharacteristic(FBLEDevice, FHRMeasurementGattCharact);
      btnMonitorize.Text := 'Stop monitoring'
    end
    else
    begin
      BluetoothLE1.UnSubscribeToCharacteristic(FBLEDevice, FHRMeasurementGattCharact);
      btnMonitorize.Text := 'Start monitoring';
      ClearData;
    end;

    btnMonitorize.Enabled := True;
  end
  else begin
    Memo1.Lines.Add('TMP Characteristic not found');
    lblBPM.Font.Size := 13;
    lblBPM.Text := 'TMP Characteristic not found';
    btnMonitorize.Enabled := False;
  end;
end;

procedure TfrmTemperatureMonitor.FormShow(Sender: TObject);
begin
    {$IFDEF ANDROID}
  FLocationPermission := JStringToString
    (TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION);
{$ENDIF}
end;

procedure TfrmTemperatureMonitor.GetServiceAndCharacteristics;
var
  I, J, K: Integer;
begin
  for I := 0 to FBLEDevice.Services.Count - 1 do
  begin
    Memo1.Lines.Add(FBLEDevice.Services[I].UUIDName + ' : ' + FBLEDevice.Services[I].UUID.ToString);
    for J := 0 to FBLEDevice.Services[I].Characteristics.Count - 1 do begin
      Memo1.Lines.Add('--> ' + FBLEDevice.Services[I].Characteristics[J].UUIDName + ' : ' +
                      FBLEDevice.Services[I].Characteristics[J].UUID.ToString);
      for K := 0 to FBLEDevice.Services[I].Characteristics[J].Descriptors.Count - 1 do begin
        Memo1.Lines.Add('----> ' + FBLEDevice.Services[I].Characteristics[J].Descriptors[K].UUIDName + ' : ' +
                      FBLEDevice.Services[I].Characteristics[J].Descriptors[K].UUID.ToString);
      end;
    end;
  end;

  FHRGattService := nil;
  FHRMeasurementGattCharact := nil;
  FBodySensorLocationGattCharact := nil;

  FHRGattService := BluetoothLE1.GetService(FBLEDevice, TEMPSERVICE);
  if FHRGattService <> nil then
  begin
    Memo1.Lines.Add('Service found');
    FHRMeasurementGattCharact := BluetoothLE1.GetCharacteristic(FHRGattService, HRMEASUREMENT_CHARACTERISTIC);
    FBodySensorLocationGattCharact := BluetoothLE1.GetCharacteristic(FHRGattService, BODY_SENSOR_LOCATION_CHARACTERISTIC);
  end
  else
  begin
    Memo1.Lines.Add('Service not found');
    lblBPM.Font.Size := 26;
    lblBPM.Text := 'Service not found';
  end;

  EnableTemperatureMonitorize(True);
  ReadBodySensorLocation;
end;

procedure TfrmTemperatureMonitor.ManageCharacteristicData(const ACharacteristic: TBluetoothGattCharacteristic);
begin
  if ACharacteristic.UUID = HRMEASUREMENT_CHARACTERISTIC then begin
    DisplayTemperatureMeasurementData(ACharacteristic.Value);
  end;

  if ACharacteristic.UUID = BODY_SENSOR_LOCATION_CHARACTERISTIC then begin
    DisplayBodySensorLocationData(ACharacteristic.Value[0]);
  end;
end;

procedure TfrmTemperatureMonitor.ReadBodySensorLocation;
begin
  if FBodySensorLocationGattCharact<>nil then
    BluetoothLE1.ReadCharacteristic(FBLEDevice, FBodySensorLocationGattCharact)
  else begin
    Memo1.Lines.Add('FBodySensorLocationGattCharact not found!!!');
    lblBodyLocation.Text := 'Sensor location charact not found';
  end;
end;

procedure TfrmTemperatureMonitor.BluetoothLE1CharacteristicRead(const Sender: TObject;
  const ACharacteristic: TBluetoothGattCharacteristic; AGattStatus: TBluetoothGattStatus);
var
  LSValue: string;
begin
  if AGattStatus <> TBluetoothGattStatus.Success then
    Memo1.Lines.Add('Error reading Characteristic ' + ACharacteristic.UUIDName + ': ' + Ord(AGattStatus).ToString)
  else
  begin
    LSValue := BytesToString(ACharacteristic.Value);
    Memo1.Lines.Add(ACharacteristic.UUIDName + ' Value: ' + LSValue);
    ManageCharacteristicData(ACharacteristic);
  end;
end;

procedure TfrmTemperatureMonitor.BluetoothLE1DescriptorRead(const Sender: TObject;
  const ADescriptor: TBluetoothGattDescriptor; AGattStatus: TBluetoothGattStatus);
var
  LSValue: string;
begin
  if AGattStatus <> TBluetoothGattStatus.Success then
    Memo1.Lines.Add('Error reading Characteristic ' + ADescriptor.UUIDName + ': ' + Ord(AGattStatus).ToString)
  else
  begin
    LSValue := BytesToString(ADescriptor.GetValue);
    Memo1.Lines.Add(ADescriptor.UUIDName + ' Value: ' + LSValue);
  end;
end;

procedure TfrmTemperatureMonitor.BluetoothLE1EndDiscoverDevices(const Sender: TObject;
  const ADeviceList: TBluetoothLEDeviceList);
var
  I: Integer;
begin
  // log
  Memo1.Lines.Add(ADeviceList.Count.ToString +  ' devices discovered:');
  for I := 0 to ADeviceList.Count - 1 do Memo1.Lines.Add(ADeviceList[I].DeviceName);

  if BluetoothLE1.DiscoveredDevices.Count > 0 then
  begin
    FBLEDevice := BluetoothLE1.DiscoveredDevices.First;
    FBLEDevice.DiscoverServices;
    lblDevice.Text := TempDeviceName;
    if BluetoothLE1.GetServices(FBLEDevice).Count = 0 then
    begin
      Memo1.Lines.Add('No services found!');
      lblBPM.Font.Size := 26;
      lblBPM.Text := 'No services found!';
    end
    else
      GetServiceAndCharacteristics;
  end
  else
    lblDevice.Text := 'Device not found';
end;

procedure TfrmTemperatureMonitor.btConnectClick(Sender: TObject);
begin
  GetServiceAndCharacteristics;
end;

procedure TfrmTemperatureMonitor.btnMonitorizeClick(Sender: TObject);
begin
  if btnMonitorize.Text.StartsWith('Stop') then
    EnableTemperatureMonitorize(False)
  else
    EnableTemperatureMonitorize(True)
end;

procedure TfrmTemperatureMonitor.btnScanClick(Sender: TObject);
begin
  //DoScan;
 PermissionsService.RequestPermissions([FLocationPermission],
    RequestPermissionsResult, DisplayRationale);
  // DoScan;
end;

procedure TfrmTemperatureMonitor.RequestPermissionsResult(Sender: TObject;
const APermissions: TArray<string>;
const AGrantResults: TArray<TPermissionStatus>);
begin
  // 1 permission involved: ACCESS_COARSE_LOCATION
  if (Length(AGrantResults) = 1) and
    (AGrantResults[0] = TPermissionStatus.Granted) then
    DoScan
  else
    TDialogService.ShowMessage
      ('Cannot start BLE scan as the permission has not been granted');
end;

procedure TfrmTemperatureMonitor.DisplayRationale(Sender: TObject;
const APermissions: TArray<string>; const APostRationaleProc: TProc);
begin
  TDialogService.ShowMessage
    ('We need to be given permission to discover BLE devices',
    procedure(const AResult: TModalResult)
    begin
      APostRationaleProc;
    end)
end;
procedure TfrmTemperatureMonitor.ClearData;
begin
  lblBPM.Font.Size := 26;
  lblBPM.Text := '? Deg';

end;

procedure TfrmTemperatureMonitor.DisplayBodySensorLocationData(Index: Byte);
begin
  if Index > 6 then
    lblBodyLocation.Text := ''
  else
    lblBodyLocation.Text := 'Sensor location: ' + BodySensorLocations[Index];
end;

procedure TfrmTemperatureMonitor.DisplayTemperatureMeasurementData(Data: TBytes);
var
  Flags: THRMFlags;
  LBPM: Integer;
  CurrentTime : Int64;
begin
  Flags := GetFlags(Data[0]);
  if Flags.HRValue16bits then
    LBPM := Data[1] + (Data[2] * 16)
  else
    LBPM := Data[1];

  case Flags.SensorContactStatus of
    NonSupported: lblContactStatus.Text := '';
    
  end;

  if Flags.SensorContactStatus = NonDetected then
    ClearData
  else
  begin
    lblBPM.Font.Size := 26;
    lblBPM.Text := LBPM.ToString + 'Deg';
    CurrentTime := DateTimeToUnix(Now(),False);
    TemperatureDataModule.PostData(LBPM);

  end;
end;

procedure TfrmTemperatureMonitor.DoScan;
begin
  ClearData;
  lblDevice.Text := '';
  lblBodyLocation.Text := '';
  lblContactStatus.Text := '';
  BluetoothLE1.DiscoverDevices(10000, [TEMPSERVICE]);
end;

end.
