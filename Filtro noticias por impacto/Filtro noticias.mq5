#property copyright  "Copyright - Giordano Bruno."
#property link       "mailto: giordanobr2@yahoo.com.br."
#property version    "1.0"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>

CTrade trade;
COrderInfo Myorder;
CAccountInfo Myaccount;
CPositionInfo m_position;

input int                  NumMagico               = 123456;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit(){      
   if(IsFillingTypeAllowed(_Symbol,SYMBOL_FILLING_FOK)){
      trade.SetTypeFilling(ORDER_FILLING_FOK);
   }
   else if(IsFillingTypeAllowed(_Symbol,SYMBOL_FILLING_IOC)){
      trade.SetTypeFilling(ORDER_FILLING_IOC);
   }
   else{
      trade.SetTypeFilling(ORDER_FILLING_RETURN);
   }   
   return INIT_SUCCEEDED;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){ 
   EventKillTimer();
   ObjectsDeleteAll(0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalendarioEconomico(){
   datetime date_from = TimeCurrent()-MinutosAntes*60;  // take all events from 
   datetime date_to = TimeCurrent()+MinutosDepois*60;     // take all events to

   BloqueadoPorNoticia = false;

   MqlCalendarValue values[]; 
   if(CalendarValueHistory(values, date_from, date_to, CodigoPais)) { 
      int idx = ArraySize(values)-1;
      while (idx>=0) {
         MqlCalendarEvent event; 
         ulong event_id=values[idx].event_id; 
         datetime event_date=values[idx].time;
         if(CalendarEventById(event_id,event)){
            if(BloquearAltoImpacto && event.importance == 3){
               BloqueadoPorNoticia = true;
               Print("Evento nome: "+event.name);
               Print("Evendo importacia: "+event.importance);
               Print("Evendo data: "+event_date);
            }
            if(BloquearMedioImpacto && event.importance == 2){               
               BloqueadoPorNoticia = true;
               Print("Evento nome: "+event.name);
               Print("Evendo importacia: "+event.importance);
               Print("Evendo data: "+event_date);
            }
            if(BloquearBaixoImpacto && event.importance == 1){               
               BloqueadoPorNoticia = true;
               Print("Evento nome: "+event.name);
               Print("Evendo importacia: "+event.importance);
               Print("Evendo data: "+event_date);
            }                          
         }else{
            Print("Nenhum envento com impacto encontrado para o periodo."); 
         }
         idx--;
      }
   }else{
      PrintFormat("Erro! Falha ao receber eventos para o pais codigo=%s",CodigoPais); 
      PrintFormat("Codigo do erro: %d",GetLastError()); 
   } 
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(){
   return;     
}