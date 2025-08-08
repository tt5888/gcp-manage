## 這支程式的目的
1. 為了協助用戶切換大量 GPC Project 的 Billing Account時免去操作GUI的繁瑣流程。
2. 透過程式自動化的方式，減少人為操作錯誤的機率與減少操作時間。 

## 切換帳務前確認事項 [1]
1. 是否有購買**Marketplace產品**
   1. 如果有的話，請與確認Marketplace產品的使用情況
   2. Marketplace 產品必續要透過特殊移轉流程，才能移轉到新的Billing Account
   3. 請勿直接切換Project的Billing Account，否則Marketplace產品將無法正常使用。嚴重情形可能導致資料遺失。
2. 是否有購買**CUD（Commitment Usage Discount）**，如果有，請確認CUD的使用情況
   1. CUD是針對特定資源的折扣，基本上有兩種型態：
      1. Resource-based CUDs Scope 在 Project可切換成 Billing Account
      2. Spend-based commitments Scope 在 Billing Account 不可搬遷到新的Billing Account
3. 是否有購買**Cloud Armor** 
   1. 如果您的 Cloud Billing 帳號已訂閱 Cloud Armor Enterprise Annual 服務，並且您將專案從該結帳帳號遷移到另一個結算帳號，但新的 Cloud Billing 帳號未訂閱 Cloud Armor Enterprise Annual 服務，則遷移完成後，您的專案將恢復為 Cloud Armor Standard 服務。 

## 使用說明
1. 確認你已經安裝了Google Cloud SDK (gcloud 工具)並且已經登入到你的GCP帳戶。
2. 確認你有足夠的權限來修改Billing Account和Project的設定。  
   * **Billing :** Billing Account Administrator	
   * **Project :** Project Billing Manager or Project Owner
3. 啟動腳本後，您會看到主選單。請依照以下建議的順序操作：
   1. 查詢目前可用的 Billing Accounts (僅限有啟用billing的帳戶)
   2. 匯出專案清單 **(從舊經銷商<來源> Billing Account，產出移轉Projects清單)**
   3. 執行大量Projects Billing 批次切換 **(切換到新經銷商<目標> Billing Account)**
   4. 離開腳本

## 參考文章
1. [Google Cloud Platform - 切換專案的帳務注意事項](https://cloud.google.com/billing/docs/how-to/manage-billing-account?hl=zh-tw)