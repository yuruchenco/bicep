# AzureMonitor各種リソースのARMによるデプロイについて

## 資材一覧
パス：`./bicep/BICEP/azure-monitor-test`

1. **MonitorAgent/：** 対象のLinuxにMonitorエージェントをインストールする資材（事前にVMを作成しておくこと）
    - `main.agent.bicep`
    - `main.agent.json`
    - `main.agent.parameters.json`
2. **LinkDCR/：** データ収集ルールとVMを紐づける資材（データ収集ルールは事前に作成しておくこと）
    - `main.linkdcr.bicep`
    - `main.linkdcr.json`
    - `main.linkdcr.parameters.json`
3. **MeteoricAlert/：** メトリックアラートを設定する資材（事前にVMとアクショングループを作成しておくこと）
    - `main.metric-alert.bicep`
    - `main.metric-alert.json`
    - `main.metric-alert.parameters.json`
4. **VmInsight/：** Log Analytics ワークスペースに対して VM insights を有効する資材
    - `main.vminsight.bicep`
    - `main.vminsight.parameters.json`
    - `module.vminsight.bicep`
5. **OnboardVm/：** VM insights に Azure 仮想マシンを追加する資材
    - `main.onbordvm.bicep`
    - `main.onbordvm.json`
    - `main.onbordvm.parameters.json`
6. **OnboardVmss/：** VM insights に Azure 仮想マシン スケール セットを追加する資材
    - `main.onboadvmss.bicep`
    - `main.onboadvmss.json`
    - `main.onboadvmss.parameters.json`

## 資材デプロイ方法
**VS Codeのターミナル"bash"モードで実施**

0. AzureMonitor周りの資材を管理しているフォルダへ移動
   ```bash
   cd (任意のフォルダ)/bicep/BICEP/azure-monitor-test

1. デプロイする資材のあるディレクトリへ移動
   ```bash
   cd [ディレクトリ]
   (ex. Monitorエージェントをデプロイしたい場合 cd 1.MonitorAgent)

2. （テンプレートbicepファイルを編集した場合）テンプレートbicepファイルをARMテンプレートへ変換
   ```bash
   az bicep build --file [テンプレートbicepファイル]
   (ex. Monitorエージェントをデプロイしたい場合 az bicep build --file main.agent.bicep)

3. 資材をデプロイする
   ```bash
   az deployment group create --resource-group [デプロイするリソースグループ] --template-file [ARMテンプレートファイル] --parameters [パラメータファイル]
   (ex. Monitorエージェントをデプロイしたい場合 az deployment group create --resource-group rg-bicep-monitor --template-file main.agent.bicep --parameters main.parameters.json)

## 参考リンク
1. [Linuxサーバに対するAzureMonitorエージェント設定](https://learn.microsoft.com/ja-jp/azure/azure-monitor/agents/resource-manager-agent?tabs=bicep#azure-linux-virtual-machine)
2. [データ収集ルールの関連付け](https://learn.microsoft.com/ja-jp/azure/azure-monitor/agents/resource-manager-data-collection-rules?tabs=bicep#create-rule-sample)
3. [メトリックアラートを設定](https://learn.microsoft.com/ja-jp/azure/azure-monitor/alerts/resource-manager-alerts-metric?tabs=bicep)
4. [VMInsightの有効化](https://learn.microsoft.com/ja-jp/azure/azure-monitor/vm/resource-manager-vminsights?tabs=bicep#configure-workspace)
5. [Azure 仮想マシンをオンボードする](https://learn.microsoft.com/ja-jp/azure/azure-monitor/vm/resource-manager-vminsights?tabs=bicep#onboard-an-azure-virtual-machine)
6. [Azure 仮想マシン スケール セットをオンボードする](https://learn.microsoft.com/ja-jp/azure/azure-monitor/vm/resource-manager-vminsights?tabs=bicep#onboard-an-azure-virtual-machine-scale-set)
