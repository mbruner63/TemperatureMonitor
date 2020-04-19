unit uBackEnd;

interface

uses
  System.SysUtils, System.Classes, IPPeerClient, REST.Backend.ServiceTypes,
  REST.Backend.MetaTypes, REST.Backend.KinveyServices, System.JSON,
  REST.Backend.KinveyProvider, REST.Backend.Providers,
  REST.Backend.ServiceComponents;

type
  TTemperatureDataModule = class(TDataModule)
    BackendStorage1: TBackendStorage;
    KinveyProvider1: TKinveyProvider;
  private
    { Private declarations }
  public
    { Public declarations }
    function PostData( Temperature: Integer; CurrentTime: Int64): Integer;
  end;

var
  TemperatureDataModule: TTemperatureDataModule;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}
{$R *.dfm}


function TTemperatureDataModule.PostData(Temperature: Integer; CurrentTime: Int64): Integer;
var
  LJSONObject: TJSONObject;
  LEntity: TBackendEntityValue;

begin

  LJSONObject := TJSONObject.Create;






  LJSONObject.AddPair('Temperature', TJSONNumber.Create(Temperature));
  LJSONObject.AddPair('UTC', TJSONNumber.Create(CurrentTime));

  BackendStorage1.Storage.CreateObject('Temperatures', LJSONObject, LEntity);

  LJSONObject.Free;

end;


end.
