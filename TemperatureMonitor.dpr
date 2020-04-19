//---------------------------------------------------------------------------

// This software is Copyright (c) 2015 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

program TemperatureMonitor;

uses
  System.StartUpCopy,
  FMX.Forms,
  UTemperatureForm in 'UTemperatureForm.pas' {frmTemperatureMonitor},
  uBackEnd in 'uBackEnd.pas' {TemperatureDataModule: TDataModule};

begin
  Application.Initialize;
  Application.CreateForm(TfrmTemperatureMonitor, frmTemperatureMonitor);
  Application.CreateForm(TTemperatureDataModule, TemperatureDataModule);
  Application.Run;
end.
