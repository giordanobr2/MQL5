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
input string               ConfiguracoesSL         = "ESTRATEGIAS PARA STOP LOSS:";
input bool                 Breakeven               = true;
input int                  PlusPoints_breakeven    = 500; // plus points, 0 - without
input int                  StepSL_plus_breakeven   = 200; // step breakeven, 0 - without
input bool                 Trailing                = true;
input int                  PlusPoints_trail        = 300; // plus points, 0 - without
input int                  StepSL_plus_trail       = 100; // trailing step, 0 - without


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
//| Modificar SL                                                     |
//+------------------------------------------------------------------+
void Modify(string position_symbol, ulong position_ticket, int MagicNum ,double TakeProfit, double StopLoss){
   //--- Atualização e inicialização do pedido e o seu resultado
   MqlTradeRequest request={};
   MqlTradeResult  result={};
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   if(IsFillingTypeAllowed(position_symbol,SYMBOL_FILLING_FOK)){      
      request.type_filling = ORDER_FILLING_FOK;
   }
   else if(IsFillingTypeAllowed(position_symbol,SYMBOL_FILLING_IOC)){          
      request.type_filling = ORDER_FILLING_IOC;
   }
   else{      
      request.type_filling = ORDER_FILLING_RETURN;    
   }

   //--- parâmetros do pedido   
   request.action    = TRADE_ACTION_SLTP;
   request.symbol    = position_symbol;
   request.position  = position_ticket; 
   request.sl        = NormalizeDouble(StopLoss, SymbolInfoInteger(position_symbol, SYMBOL_DIGITS)); 
   request.tp        = NormalizeDouble(TakeProfit, SymbolInfoInteger(position_symbol, SYMBOL_DIGITS));
   request.magic     = MagicNum;
   
   //--- envio do pedido
   if(!OrderSend(request,result))
      PrintFormat("Erro ao enviar a ordem de compra: %d",GetLastError());     // se não for possível enviar o pedido, sairá um código de erro
}


//+------------------------------------------------------------------+
//| Trailing do stop loss                                            |
//+------------------------------------------------------------------+
void fTrailing(){
   int _tp=PositionsTotal();
   for(int i=_tp-1; i>=0; i--){
      string _p_symbol=PositionGetSymbol(i);
      if(_p_symbol!=_Symbol) continue;
      if(NumMagico>=0 && NumMagico!=PositionGetInteger(POSITION_MAGIC)) continue;
      double _s_point = SymbolInfoDouble (_p_symbol, SYMBOL_POINT);
      long   _s_levSt = SymbolInfoInteger(_p_symbol, SYMBOL_TRADE_STOPS_LEVEL);
      int    _s_dig   = (int)SymbolInfoInteger(_p_symbol,SYMBOL_DIGITS);
      double _p_sl    = PositionGetDouble(POSITION_SL);
      double _p_tp    = PositionGetDouble(POSITION_TP);
      double _p_op    = PositionGetDouble(POSITION_PRICE_OPEN);
      ulong  _p_tick  = PositionGetTicket(i);
      //ulong  _p_tick  = m_position.Ticket(); 
      if(_p_sl==0) _p_sl=_p_op;
      //---
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
         if(Breakeven && _p_sl<_p_op+StepSL_plus_breakeven*_s_point) continue;
         if(!Breakeven && _p_sl<_p_op) _p_sl=_p_op;
         double Bid=SymbolInfoDouble(_p_symbol,SYMBOL_BID);
         if(_p_sl+PlusPoints_trail*_s_point<=Bid){
            double _new_sl=Bid-PlusPoints_trail*_s_point+StepSL_plus_trail*_s_point;
            if(Bid-_new_sl<_s_levSt*_s_point) _new_sl=Bid-_s_levSt*_s_point;
            _new_sl=NormalizeDouble(_new_sl,_s_dig);
            if(_new_sl<=_p_sl)continue;
            Modify(_Symbol, _p_tick, NumMagico, _p_tp, _new_sl); 
         }
      }else
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
         if(Breakeven && _p_sl>_p_op-StepSL_plus_breakeven*_s_point) continue;
         if(!Breakeven && _p_sl>_p_op) _p_sl=_p_op;
         double Ask=SymbolInfoDouble(_p_symbol,SYMBOL_ASK);
         if(_p_sl-PlusPoints_trail*_s_point>=Ask){
            double _new_sl=Ask+PlusPoints_trail*_s_point-StepSL_plus_trail*_s_point;
            if(_new_sl-Ask<_s_levSt*_s_point) _new_sl=Ask+_s_levSt*_s_point;
            _new_sl=NormalizeDouble(_new_sl,_s_dig);
            if(_new_sl>=_p_sl)continue;
            Modify(_Symbol, _p_tick, NumMagico, _p_tp, _new_sl); 
         }
      }
   }
}
  
  
//+------------------------------------------------------------------+
//| Breakeven do stop loss                                           |
//+------------------------------------------------------------------+
void fBreakeven(){
   int _tp=PositionsTotal();
   for(int i=_tp-1; i>=0; i--){
      string _p_symbol=PositionGetSymbol(i);
      if(_p_symbol!=_Symbol) continue;
      if(NumMagico>=0 && NumMagico!=PositionGetInteger(POSITION_MAGIC)) continue;
      double _s_point = SymbolInfoDouble(_p_symbol, SYMBOL_POINT);
      long   _s_levSt = SymbolInfoInteger(_p_symbol, SYMBOL_TRADE_STOPS_LEVEL);
      int    _s_dig   = (int)SymbolInfoInteger(_p_symbol,SYMBOL_DIGITS);
      double _p_sl    = PositionGetDouble(POSITION_SL);
      double _p_tp    = PositionGetDouble(POSITION_TP);
      double _p_op    = PositionGetDouble(POSITION_PRICE_OPEN);
      ulong  _p_tick  = PositionGetTicket(i);
      //ulong  _p_tick  = m_position.Ticket();
      if(_p_sl==0) _p_sl=_p_op;
      //---
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
         if(_p_sl>=_p_op+StepSL_plus_breakeven*_s_point) continue;
         double Bid=SymbolInfoDouble(_p_symbol,SYMBOL_BID);
         if(_p_op+PlusPoints_breakeven*_s_point<=Bid){
            double _new_sl=_p_op+StepSL_plus_breakeven*_s_point;
            if(Bid-_new_sl<_s_levSt*_s_point) _new_sl=Bid-_s_levSt*_s_point;
            _new_sl=NormalizeDouble(_new_sl,_s_dig);
            if(_new_sl<=_p_sl)continue;            
            Modify(_Symbol, _p_tick, NumMagico, _p_tp, _new_sl);   
         }
      }
      else
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
         if(_p_sl<=_p_op-StepSL_plus_breakeven*_s_point) continue;
         double Ask=SymbolInfoDouble(_p_symbol,SYMBOL_ASK);
         if(_p_op-PlusPoints_breakeven*_s_point>=Ask){
            double _new_sl=_p_op-StepSL_plus_breakeven*_s_point;
            if(_new_sl-Ask<_s_levSt*_s_point) _new_sl=Ask+_s_levSt*_s_point;
            _new_sl=NormalizeDouble(_new_sl,_s_dig);
            if(_new_sl>=_p_sl)continue;
            Modify(_Symbol, _p_tick, NumMagico, _p_tp, _new_sl); 
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(){
   
   if(Breakeven){ fBreakeven(); }   
   if(Trailing){ fTrailing(); }
   
   return;     
}