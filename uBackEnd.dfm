object TemperatureDataModule: TTemperatureDataModule
  OldCreateOrder = False
  Height = 150
  Width = 215
  object BackendStorage1: TBackendStorage
    Provider = KinveyProvider1
    Left = 48
    Top = 40
  end
  object KinveyProvider1: TKinveyProvider
    ApiVersion = '3'
    AppKey = 'kid_HkJ6ekcuL'
    AppSecret = '2e9f2ae074ca4ff5a2fade2c5c1a053f'
    MasterSecret = 'a9a5413bae454bf48cef1ff43c025691'
    Left = 144
    Top = 48
  end
end
