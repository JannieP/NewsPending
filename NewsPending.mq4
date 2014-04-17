//+------------------------------------------------------------------+
//|                                                  NewsPending.mq4 |
//|                                      Copyright © 2011, c0nan.net |
//|                                                 http://c0nan.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, c0nan.net"
#property link      "http://c0nan.net"

//--- input parameters
extern int       Deviation=5;
extern int       TakeProfit=10;
extern int       StopLoss=5;
extern double    LotSize=0.01;
extern int       Slippage=3;
extern datetime  ExecutionDateDay = D'Year.Month.Day Hour:Minute:Seconds';
extern bool      OpenNOW=false;
extern int       DateSlipageSeconds=30;
extern int       DelayCloseMinutes=30;
extern bool      DoSecondTrade=false;
extern int       SecondTradeTrail=5;
extern bool      DeleteCounterTrade=true;
extern bool      CloseAllTrades=false;

string Version;
bool   OrderOpened=false;
bool   FirstOrderClosed=false;
int    MagicNumber=0;
int Factor=1;
bool Simulate=false;



//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   Version="2.0";
   if (!OpenNOW){
      OrderOpened = false;
   }
   MathSrand(TimeLocal());
   MagicNumber = MathRand();
   if (Digits == 3 || Digits == 5) {Factor=10;}else{Factor=1;}
   CheckState();
//----
   return(0);   
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start(){
//----
   if (CloseAllTrades){ 
      CloseTrades();
      return(0);
   }
   if (DeleteCounterTrade && OrderOpened && !Simulate){
      DeleteCounter();
   }
   if (DoSecondTrade && OrderOpened && !Simulate){
      DoSecond();
   }
   if ((TimeCurrent() >= ExecutionDateDay && TimeCurrent() <= (ExecutionDateDay + DateSlipageSeconds) && !OrderOpened)|| ((Simulate || OpenNOW) && !OrderOpened)){
      Print("Opening Trades");
      OpenTrades();
   }

//----
   return(0);
}

int CheckState(){
   for(int OrderIndex=0;OrderIndex<OrdersTotal();OrderIndex++){
      OrderSelect(OrderIndex, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() == Symbol()){
         if((OrderComment() == "NewsPending_Long_01" || OrderComment() == "NewsPending_Short_01" || OrderComment() == "NewsPending_Long_02" || OrderComment() == "NewsPending_Short_02")){
            Print("Orders Found");
            OrderOpened=true;
            break;
         }
      }
   }

}

int DeleteCounter(){
   bool FoundOpenOrder=false;
   bool FoundToCloseOrder=false;
   int OpenOrderMagic=0;
   int OrderMagic=0;
   int OrderToClose=0;
   int OrderFoundType=99;
   int OrderIndex=0;
   for(OrderIndex=0;OrderIndex<OrdersTotal();OrderIndex++){
      OrderSelect(OrderIndex, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() == Symbol()){
         if(OrderType() <= 1 && (OrderComment() == "NewsPending_Long_01" || OrderComment() == "NewsPending_Short_01" || OrderComment() == "NewsPending_Long_02" || OrderComment() == "NewsPending_Short_02")){
            Print("Opening Trade Found");
            OpenOrderMagic = OrderMagicNumber();
            FoundOpenOrder=true;
            OrderFoundType=OrderType();
            break;
         }
      }
   }
   if (FoundOpenOrder){
      for(OrderIndex=0;OrderIndex<OrdersTotal();OrderIndex++){
         OrderSelect(OrderIndex, SELECT_BY_POS, MODE_TRADES);
         if (OrderSymbol() == Symbol()){
            if(OrderType() > 1 && FoundOpenOrder){
               Print("Closing Opisite Pending Trades");
               OrderSelect(OrderIndex, SELECT_BY_POS, MODE_TRADES);
               OrderDelete(OrderTicket(),OrangeRed);
            }
         }
      }
   }
}

int DoSecond(){
   bool FoundFirstOrder=false;
   Print("1");
   for(int OrderIndex=0;OrderIndex<OrdersTotal();OrderIndex++){
      OrderSelect(OrderIndex, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() == Symbol()){
         if (OrderType() >1 && (OrderComment() == "NewsPending_Long_01" || OrderComment() == "NewsPending_Short_01" || OrderComment() == "NewsPending_Long_02" || OrderComment() == "NewsPending_Short_02")){
            FoundFirstOrder=true;
            break;
         }
         if((OrderComment() == "NewsPending_Long_01" || OrderComment() == "NewsPending_Short_01")){
            Print("FirstOrder Still Open");
            FoundFirstOrder=true;
            continue;
         }
         if((OrderComment() == "NewsPending_Long_02" || OrderComment() == "NewsPending_Short_02") && FirstOrderClosed){
            Print("No First Order, Start Trailing Stop");
            if(OrderType() == 0){
               //Print("OrderType is Long("+(Bid)+"|"+(OrderStopLoss()+(Point * SecondTradeTrail*Factor))+"|||"+(Bid)+")");
               //if(Bid-OrderOpenPrice()>(Point*Factor*SecondTradeTrail)){
                  if(OrderStopLoss()<Bid-(Point*Factor*SecondTradeTrail)){
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-(Point*Factor*SecondTradeTrail),OrderTakeProfit(),0,Green);
                     Print("Trailing Stop Updated Up");
                  }
              //}
            }
            if(OrderType() == 1){
               Print("OrderType is Short");
               //if(OrderOpenPrice()-Ask>Point*Factor*SecondTradeTrail){
                  if(OrderStopLoss()>Ask+(Point*Factor*SecondTradeTrail)){
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(Point*Factor*SecondTradeTrail),OrderTakeProfit(),0,Blue);
                     Print("Trailing Stop Updated Down");
                  }
              //}
            }
         }
      }
   }
   if (!FoundFirstOrder){
      FirstOrderClosed=true;
   }
}

 
int OpenTrades(){
   bool OrderBuy=false;
   bool OrderSell=false;
   bool OrderBuy2=false;
   bool OrderSell2=false;
   //int TakeProfitLocal = 0;
   bool ModResult=0;
   while (true){
      if (!OrderBuy || (!OrderBuy2 && DoSecondTrade)){
         int ticket=0;
         if (!Simulate){
            if(OrderBuy){
               Print("Opening Long Pending 2");
               ticket=OrderSend(Symbol(),OP_BUYSTOP,LotSize,Ask + Deviation*Point*Factor,Slippage,0,0,"NewsPending_Long_02",MagicNumber,TimeCurrent() + DelayCloseMinutes*60,Blue);
            }else{
               Print("Opening Long Pending 1");
               ticket=OrderSend(Symbol(),OP_BUYSTOP,LotSize,Ask + Deviation*Point*Factor,Slippage,0,0,"NewsPending_Long_01",MagicNumber,TimeCurrent() + DelayCloseMinutes*60,Blue);
            }
         }else{
            ticket=0;
            OrderBuy=true;
            Print("Send Pending(symbol,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color)");
            Print("Send Pending("+Symbol()+","+OP_BUYSTOP+","+LotSize+","+ (Ask + Deviation*Point*Factor) +","+Slippage+","+ (OrderOpenPrice()-StopLoss*Point*Factor) +","+ (OrderOpenPrice()+TakeProfit*Point*Factor) +",NewsPending_Long_01,"+MagicNumber+","+TimeCurrent() + DelayCloseMinutes*60+",Blue)");
         }
         if(ticket>0){
            //OrderBuy = true;
            while (true){
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) {
                  if(OrderBuy){
                     OrderBuy2 = true;
                     ModResult = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-StopLoss*Point*Factor,0,OrderExpiration(),CLR_NONE);
                  }else{
                     OrderBuy = true;
                     ModResult = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-StopLoss*Point*Factor,OrderOpenPrice()+TakeProfit*Point*Factor,OrderExpiration(),CLR_NONE);
                  }
                  if(ModResult){
                     Print("Long order Modified : ",OrderOpenPrice());
                  }else{
                     if (Do_Error(GetLastError())==1){
                        continue;
                     }else{
                        return(0);
                     }
                  }
                  break;
               }
            }
         }else{
            if (!Simulate){
               if (Do_Error(GetLastError())==1){
                  continue;
               }else{
                  return(0);
               }
            }
         }
      }
      if (!OrderSell || (!OrderSell2 && DoSecondTrade)){
         if (!Simulate){
            if(OrderSell){
               Print("Opening Short Pending 2");
               ticket=OrderSend(Symbol(),OP_SELLSTOP,LotSize,Bid - Deviation*Point*Factor,Slippage,0,0,"NewsPending_Short_02",MagicNumber,TimeCurrent() + DelayCloseMinutes*60,Blue);
            }else{
               Print("Opening Short Pending 1");
               ticket=OrderSend(Symbol(),OP_SELLSTOP,LotSize,Bid - Deviation*Point*Factor,Slippage,0,0,"NewsPending_Short_01",MagicNumber,TimeCurrent() + DelayCloseMinutes*60,Blue);
            }
         }else{
            ticket=0;
            OrderSell=true;
            Print("Send Pending(symbol,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color)");
            Print("Send Pending("+Symbol()+","+OP_SELLSTOP+","+LotSize+","+ (Bid - Deviation*Point*Factor) +","+Slippage+","+ (OrderOpenPrice()+StopLoss*Point*Factor) +","+ (OrderOpenPrice()-TakeProfit*Point*Factor) +",NewsPending_Short_01,"+MagicNumber+","+TimeCurrent() + DelayCloseMinutes*60+",Blue)");
         }
         if(ticket>0){
            //OrderSell = true;
            while (true){
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)){
                  if(OrderSell){
                     OrderSell2 = true;
                     ModResult = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+StopLoss*Point*Factor,0,OrderExpiration(),CLR_NONE);
                  }else{
                     OrderSell = true;
                     ModResult = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+StopLoss*Point*Factor,OrderOpenPrice()-TakeProfit*Point*Factor,OrderExpiration(),CLR_NONE);
                  }
                  if(ModResult){
                     Print("Short pending order Modified : ",OrderOpenPrice());
                  }else{
                     if (Do_Error(GetLastError())==1){
                        continue;
                     }else{
                        return(0);
                     }
                  }
                  break;
               }      
            }
         }else{
            if(!Simulate){
               if (Do_Error(GetLastError())==1){
                  continue;
               }else{
                  return(0);
               }
            }
         }
      }
      if (OrderBuy && OrderSell){ 
         if (DoSecondTrade && (!OrderBuy2 || !OrderSell2)){
         }else{
            OrderOpened = true;
            break;
         }
      }
   }
   return(0);
}

int CloseTrades(){
   double currentPrice=0;
   int total  = OrdersTotal();
   if (total<=0)return(0);
   for(int cnt=0;cnt<total;cnt++){
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol() == Symbol() && (OrderComment() == "NewsPending_Long_01" || OrderComment() == "NewsPending_Short_01" || OrderComment() == "NewsPending_Long_02" || OrderComment() == "NewsPending_Short_02")){
         while(true){
            if(OrderType() <= 1){
               if(OrderType()==OP_BUY){
                  currentPrice = Bid;
               }else{
                  currentPrice = Ask;
               }
               if(OrderClose(OrderTicket(),OrderLots(),currentPrice,3,Red)){
                  Print("Order closed");
               }else{
                  if (Do_Error(GetLastError())==1){
                     continue;
                  }else{
                     return(0);
                  }
               }
            }else{
               if(OrderDelete(OrderTicket(),OrangeRed)){
                  Print("Order deleted");
               }else{
                  if (Do_Error(GetLastError())==1){
                     continue;
                  }else{
                     return(0);
                  }
               }
            }
            break;
         }
      }
   }
   Print("All Order for this "+Symbol()+" has been closed/deleted.");
   return(0);
}
//+------------------------------------------------------------------+

int Do_Error(int Error)                        // Function of processing errors
  {
   switch(Error)
     {                                          // Not crucial errors            
      case  4: Alert("Trade server is busy. Trying once again..");
         Sleep(3000);                           // Simple solution
         return(1);                             // Exit the function
      case 129:Alert("Invalid Price. Trying once again..");
         RefreshRates();                        // Refresh rates
         return(1);                             // Exit the function
      case 135:Alert("Price changed. Trying once again..");
         RefreshRates();                        // Refresh rates
         return(1);                             // Exit the function
      case 136:Alert("No prices. Waiting for a new tick..");
         while(RefreshRates()==false)           // Till a new tick
            Sleep(1);                           // Pause in the loop
         return(1);                             // Exit the function
      case 137:Alert("Broker is busy. Trying once again..");
         Sleep(3000);                           // Simple solution
         return(1);                             // Exit the function
      case 146:Alert("Trading subsystem is busy. Trying once again..");
         Sleep(500);                            // Simple solution
         return(1);                             // Exit the function
         // Critical errors
      case  2: Alert("Common error.");
         return(0);                             // Exit the function
      case  5: Alert("Old terminal version.");
         //CriticalError=True;                    // Terminate operation
         return(0);                             // Exit the function
      case 64: Alert("Account blocked.");
         //CriticalError=True;                    // Terminate operation
         return(0);                             // Exit the function
      case 133:Alert("Trading forbidden.");
         return(0);                             // Exit the function
      case 134:Alert("Not enough money to execute operation.");
         return(0);                             // Exit the function
      case 4109:Alert("Trade is not allowed. Enable checkbox 'Allow live trading' in the expert properties.");
         return(0);
      default: Alert("Error occurred: ",Error);  // Other variants   
         return(0);                             // Exit the function
     }
  }
