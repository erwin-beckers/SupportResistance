//+------------------------------------------------------------------+
//|                                            SupportResistance.mq4 |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property version   "1.00"
#property strict
#property indicator_chart_window

#include <CZigZag.mqh>

// v1.01
//   - added S&R for H1 (press 'i' to turn on/off)
//
// v1.00
//   - first version
//   - todo : use timeout timer for chart events & refresh
//   - (1-5)   = set detail
//   = (d/w/h) = turn daily, weekly, hour4 on/off
//   

enum Details 
{
   Minium,
   MediumLow,
   Medium,
   MediumHigh,
   Maximum
};


extern string      __srSettings__  = "---- S/R settings ----";
extern int         BarsHistory     = 3000;
extern Details     Detail          = Medium;
extern bool        ShowSR_1Hours   = false;
extern bool        ShowSR_4Hours   = false;
extern bool        ShowSR_Daily    = true;
extern bool        ShowSR_Weekly   = false;
extern bool        ShowAgeLabels   = true;
extern bool        ShowLastTouch   = false; 
extern string      __colors__      = "---- S/R settings ----";
extern color       ColorAge1       = Silver;
extern color       ColorAge2       = clrDarkGray;
extern color       ColorAge3       = LightSeaGreen;
extern color       ColorAge4       = Teal;
extern color       ColorText       = Black;


color        Colors[]    = {Silver,clrDarkGray, LightSeaGreen,Teal};
double       _maxDistance;
int          _lineCnt=0;


//+------------------------------------------------------------------+
class SRLine
{
public:
   int      StartBar;
   int      EndBar;
   datetime StartDate;
   datetime EndDate;
   double   Price;
   int      Touches;  
   int      Timeframe;
};


//+------------------------------------------------------------------+
void ClearAll(string key="")
{ 
   _lineCnt = 0;
   bool deleted = false;
   do {
      deleted = false;
      for (int i = 0; i < ObjectsTotal();++i)
      {
         string name = ObjectName(0, i);
         if (name== "@info" || StringSubstr(name, 0, 1+StringLen(key)) == "@"+key)
         {
            ObjectDelete(0, name);
            deleted = true;
            break;
         }
      }
   } while (deleted);
}

//+------------------------------------------------------------------+
void DrawLine(SRLine* line, int maxTouches, int maxBars, string key)
{
   string name = "@"+key+" (" + DoubleToStr(line.Price,5) + ") " + TimeToStr(line.StartDate,TIME_DATE)+" - " + TimeToStr(line.EndDate,TIME_DATE);
   
   if (ShowAgeLabels)
   {
      int xoff = ShowLastTouch ? 210:90;
      string timeFrame = "H4";
      if (line.Timeframe == PERIOD_H1) timeFrame = "H1";
      if (line.Timeframe == PERIOD_H4) timeFrame = "H4";
      if (line.Timeframe == PERIOD_D1) timeFrame = "D1";
      if (line.Timeframe == PERIOD_W1) timeFrame = "W1";
      
      double daysLastTouch = (double)(TimeCurrent() - line.EndDate) / (60*60*24);
      double days = (double) (TimeCurrent()  - line.StartDate) / (60*60*24);
      int yrs     = MathFloor(days / 356.0);
     
      if (yrs >= 1 )
      {
         int X = 0;
         int Y = 0;
         ChartTimePriceToXY(0,0,TimeCurrent(), line.Price, X, Y);
         ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
         ObjectSet(name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
         ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
         ObjectSet(name, OBJPROP_XDISTANCE, xoff);
         ObjectSet(name, OBJPROP_YDISTANCE, Y-13);
         ObjectSet(name, OBJPROP_BACK, false);
         string txt= timeFrame+" "+ IntegerToString((int)yrs)+ " years old.";
         if (ShowLastTouch) txt=txt+" Last touch:"+IntegerToString( (int)daysLastTouch)+" days ago";
         ObjectSetText(name, txt, 8, "Arial", ColorText);
         _lineCnt++;
      }
      else
      {
         int months     = TimeMonth( TimeCurrent() ) - TimeMonth(line.StartDate);
         if (months < 0) months += 12;
         if (months > 1)
         {
            int X = 0;
            int Y = 0;
            ChartTimePriceToXY(0,0,TimeCurrent(),line.Price, X, Y);
            ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
            ObjectSet(name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
            ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
            ObjectSet(name, OBJPROP_XDISTANCE, xoff);
            ObjectSet(name, OBJPROP_YDISTANCE, Y-13);
            ObjectSet(name, OBJPROP_BACK, false);
            string txt=timeFrame+" "+IntegerToString((int)months)+ " months old.";
            if (ShowLastTouch) txt=txt+" Last touch:"+IntegerToString((int)daysLastTouch)+" days ago";
            ObjectSetText(name, txt, 8, "Arial", ColorText);
            _lineCnt++;
         }
         else
         {
            int X = 0;
            int Y = 0;
            ChartTimePriceToXY(0,0,TimeCurrent(),line.Price, X, Y);
            ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
            ObjectSet(name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
            ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
            ObjectSet(name, OBJPROP_XDISTANCE, xoff);
            ObjectSet(name, OBJPROP_YDISTANCE, Y-13);
            ObjectSet(name, OBJPROP_BACK, false);
            string txt=timeFrame+" "+IntegerToString((int)days)+ " days old.";
            if (ShowLastTouch) txt=txt+" Last touch:"+IntegerToString((int)daysLastTouch)+" days ago";
            ObjectSetText(name, txt, 8, "Arial", ColorText);
            _lineCnt++;
         }
      }
   }
   
   name = "@"+key+" " + DoubleToStr(line.Price,4) + " " + TimeToStr(line.StartDate, TIME_DATE) + " - " + TimeToStr(line.EndDate, TIME_DATE) + "  #:" + IntegerToString(line.Touches);
   _lineCnt++;
   
   int width = 1;
   double bars = MathAbs(line.EndBar - line.StartBar);
   if (bars > 0) 
   {
      double percentage = bars / ((double)maxBars);
      width =(int)MathAbs(4 * percentage);
   }
   
   color clr = Colors[0];
   double percentage = (((double)line.Touches) / maxTouches) ;
   if (percentage <= 0.25) clr = Colors[0];
   else if (percentage <= 0.50) clr = Colors[1];
   else if (percentage <= 0.75) clr = Colors[2];
   else clr = Colors[3];
   
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, line.Price);
   ObjectSet(name, OBJPROP_COLOR, clr);
   ObjectSet(name, OBJPROP_WIDTH, width);
   ObjectSet(name, OBJPROP_BACK, true);
   ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
    
}


//+------------------------------------------------------------------+
int GetTouches(CZigZag* &zigZag, int period, int barPrice,int maxBars, double& price, datetime& startTime, int& startBar)
{
   int    cnt        = 0;
   double totalPrice = price;
   double totalCnt   = 1.0; 
   double lowest     = price;
   double highest    = price;
   bool  logEnable   = false;// price >= 113.400 && price <=116.00;
   
   if (logEnable) Print("Get touches for price:",price);
   for (int bar = barPrice + 1; bar < maxBars; bar++)
   {  
      ARROW_TYPE arrow=zigZag.GetArrow(bar);
      if (arrow==ARROW_NONE) continue;
      
      double lo = iLow (Symbol(), period, bar);
      double hi = iHigh(Symbol(), period, bar);
      
      double diffLo = MathAbs(lo  - price);
      double diffHi = MathAbs(hi - price);
      if (diffLo < _maxDistance )
      {
         cnt++;
         startTime   = iTime(Symbol(), period, bar);
         startBar    = bar;
         totalPrice += lo;
         totalCnt   += 1.0;
         lowest = MathMin(lowest,lo);
         double pips=diffLo / (10.0 * Point());
         //if (logEnable) Print("price:",price," bar:",bar, " low:",lo, " date:", startTime, " pips:",pips);
      }
      else if ( diffHi <= _maxDistance) 
      {
         cnt++;
         startTime  = iTime(Symbol(), period, bar);
         startBar   = bar;
         totalPrice += hi;
         totalCnt   += 1.0;
         highest = MathMax(highest,hi);
         double pips=diffHi / (10.0 * Point());
         //if (logEnable) Print("price:",price," bar:",bar, " hi:",hi,"  date:",startTime, " pips:",pips);
      }
   }
   
   //if (logEnable) Print("lowest:", lowest,"  highest:", highest);
   //double diffHi=MathAbs(highest-price);
   //double diffLo=MathAbs(lowest-price);
   //if (diffHi > diffLo) price=diffHi;
   //else price=diffLo;
   
   
  //price = totalPrice / totalCnt;
   return cnt;
}

//+------------------------------------------------------------------+
bool DoesLevelExists(int bar, SRLine* &lines[], int maxlines, double price, datetime mostRecent)
{
   for (int i=0; i < maxlines;++i)
   {
      double diff = MathAbs(price - lines[i].Price);
      if (diff < _maxDistance) 
      {
         if ( mostRecent > lines[i].EndDate)
         {
            lines[i].EndDate = mostRecent;   
            lines[i].EndBar  = bar;
         }
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
void CalculateSRForTimeFrame(int period, int& maxLine, SRLine* &lines[] )
{
   int barsAvailable = iBars(Symbol(), period);
   int bars = MathMin( BarsHistory, barsAvailable); 
   
   
   ExtDepth             = 12;
   ExtDeviation         =  5;
   ExtBackstep          =  3; 
   
   int lowestBar       = iLowest(Symbol() , period, MODE_LOW , bars, 0);
   int highestBar      = iHighest(Symbol(), period, MODE_HIGH, bars, 0);
   double highestPrice = iHigh(Symbol(), period, highestBar);
   double lowestPrice  = iLow(Symbol() , period, lowestBar);
   
   double priceRange = highestPrice - lowestPrice;
  
   double mult   = (Digits==3 || Digits==5) ? 10.0 : 1.0;
   mult *= Point();
    
   double div = 30.0;
   switch (Detail)
   {
      case Minium:
         div=10.0;
      break;
      case MediumLow:
         div=20.0;
      break;
      case Medium:
         div=30.0;
      break;
      case MediumHigh:
         div=40.0;
      break;
      case Maximum:
         div=50.0;
      break;
   }
   _maxDistance =  priceRange/div;
   
   CZigZag* zigZag = new CZigZag(bars,  period);  
   zigZag.Refresh(Symbol());
   
   bool skipFirstArrow=true;
   for (int bar = 1; bar < bars; bar++)
   {
      ARROW_TYPE arrow = zigZag.GetArrow(bar);
      if (arrow == ARROW_NONE) continue; 
      if (skipFirstArrow)
      {
         skipFirstArrow=false;
         continue;
      }
      
      if (arrow == ARROW_BUY) 
      {  
         double   price = iLow (Symbol(), period, bar);
         datetime time  = iTime(Symbol(), period, bar);
         datetime startTime = time;
         int startBar=bar;
         if (!DoesLevelExists(bar, lines, maxLine, price, startTime )) 
         {
            int touches = GetTouches(zigZag, period, bar, bars, price, startTime, startBar);
            if (touches >= 0)
            {
               lines[maxLine] = new SRLine();
               lines[maxLine].Price     = price;
               lines[maxLine].Touches   = touches;
               lines[maxLine].EndBar    = bar;
               lines[maxLine].EndDate   = time;
               lines[maxLine].StartDate = startTime;
               lines[maxLine].StartBar  = startBar;
               lines[maxLine].Timeframe = period;
               maxLine++;
            }
          }
      }
      else if (arrow==ARROW_SELL) 
      {
         double   price  = iHigh(Symbol(), period, bar);
         datetime time   = iTime(Symbol(), period, bar);
         datetime startTime = time;
         int startBar = bar;
         if (!DoesLevelExists(bar, lines, maxLine, price, startTime) )
         {
            int touches = GetTouches(zigZag, period, bar,bars, price, startTime, startBar);
            if (touches >= 0)
            {
               lines[maxLine] = new SRLine();
               lines[maxLine].Price     = price;
               lines[maxLine].Touches   = touches;
               lines[maxLine].EndBar    = bar;
               lines[maxLine].EndDate   = time;
               lines[maxLine].StartDate = startTime;
               lines[maxLine].StartBar  = startBar;
               lines[maxLine].Timeframe = period;
               maxLine++;
            }
         }
      }
   }
    
   // add s/r line for highest price
   datetime mostRecentTime = iTime(Symbol(), period,highestBar);
   if (!DoesLevelExists(highestBar, lines, maxLine, highestPrice, mostRecentTime) )
   {
      lines[maxLine] = new SRLine();
      lines[maxLine].Price     = highestPrice;
      lines[maxLine].Touches   = 1;
      lines[maxLine].StartBar  = highestBar;
      lines[maxLine].StartDate = iTime(Symbol(), period,highestBar);
      lines[maxLine].EndDate   = TimeCurrent();
      lines[maxLine].EndBar    = 0;
      lines[maxLine].Timeframe = period;
      maxLine++;
   }
   
   // add s/r line for lowest price
   mostRecentTime = iTime(Symbol(), period, lowestBar);
   if (!DoesLevelExists(lowestBar, lines, maxLine, lowestPrice, mostRecentTime) )
   {
      lines[maxLine] = new SRLine();
      lines[maxLine].Price     = lowestPrice;
      lines[maxLine].Touches   = 1;
      lines[maxLine].StartBar  = lowestBar;
      lines[maxLine].StartDate = iTime(Symbol(), period,lowestBar);
      lines[maxLine].EndDate   = TimeCurrent();
      lines[maxLine].EndBar    = 0;
      lines[maxLine].Timeframe = period;
      maxLine++;
   }
   
   
   delete zigZag;
   
}

//+------------------------------------------------------------------+
void DrawSRLines(int maxLine, SRLine* &lines[], string key)
{
   // draw lines
   int maxTouches = 0;  
   int maxBars    = 0;  
   for (int i=0; i < maxLine;++i)
   {
       maxTouches = MathMax(maxTouches, lines[i].Touches);
       maxBars    = MathMax(maxBars, MathAbs(lines[i].EndBar - lines[i].StartBar));
   }
   
   for (int i=0; i < maxLine;++i)
   {
       DrawLine(lines[i], maxTouches, maxBars, key);
       delete lines[i];
   }
}


//+------------------------------------------------------------------+
void CalcAndDrawSR(int period, string key)
{
   ClearAll(key);
   
   int     maxLine = 0;
   SRLine* lines[];
   ArrayResize(lines, 5000, 0);
   
   CalculateSRForTimeFrame(period, maxLine, lines);
   
   DrawSRLines(maxLine, lines, key);
   
   ArrayFree(lines);
}

//+------------------------------------------------------------------+
void CalculateSR()
{  
   if (ShowSR_Weekly)  CalcAndDrawSR(PERIOD_W1, "W1");
   if (ShowSR_Daily)   CalcAndDrawSR(PERIOD_D1, "D1");
   if (ShowSR_4Hours)  CalcAndDrawSR(PERIOD_H4, "H4");
   if (ShowSR_1Hours)  CalcAndDrawSR(PERIOD_H1, "H1");
   
   string txt="S/R:";
   if (ShowSR_1Hours) txt+="H1";
   if (ShowSR_4Hours) 
   {
      if (ShowSR_1Hours) txt+=",";
      txt+="H4";
   }
   if (ShowSR_Daily) 
   {
      if (ShowSR_4Hours||ShowSR_1Hours) txt+=",";
      txt+="D1";
   }
   if (ShowSR_Weekly) 
   {
      if (ShowSR_4Hours||ShowSR_Daily||ShowSR_1Hours) txt+=",";
      txt+="W1";
   }
   switch (Detail)
   {
      case Minium: txt+=" Minimum"; break;
      case MediumLow: txt+=" Medium/Low"; break;
      case Medium: txt+=" Medium"; break;
      case MediumHigh: txt+=" Medium/High"; break;
      case Maximum: txt+=" Maximum"; break;
   }
   
   ObjectCreate("@info", OBJ_LABEL, 0, 0, 0);
   ObjectSet("@info", OBJPROP_BACK, false);
   ObjectSet("@info", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet("@info", OBJPROP_XDISTANCE, 250);
   ObjectSet("@info", OBJPROP_YDISTANCE, 0);
   ObjectSetText("@info", txt, 8, "Arial", ColorText);
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   return(rates_total);
}


//+------------------------------------------------------------------+
void deinit()
{ 
   ClearAll();
}

//+------------------------------------------------------------------+
int init()
{  
   Colors[0]=ColorAge1;
   Colors[1]=ColorAge2;
   Colors[2]=ColorAge3;
   Colors[3]=ColorAge4;
   CalculateSR();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event ID
                  const long& lparam,   // Parameter of type long event
                  const double& dparam, // Parameter of type double event
                  const string& sparam)  // Parameter of type string events
{
   if (id == 9)
   {
      //Print("Chart zoomed or changed, recalculate SR");
      CalculateSR();
   }
   if (id==CHARTEVENT_KEYDOWN)
   {
      switch(lparam)
      {
         case 49://1
            Print("Detail: Minium");
            Detail=Minium; 
            CalculateSR();
         break;
         
         case 50://2
            Print("Detail: medium low");
            Detail=MediumLow; 
            CalculateSR();
         break;
         
         case 51://3
            Print("Detail: medium");
            Detail=Medium; 
            CalculateSR();
         break;
         
         case 52://4
            Print("Detail: medium high");
            Detail=MediumHigh; 
            CalculateSR();
         break;
         
         case 53://5
            Print("Detail: maximum");
            Detail=Maximum; 
            CalculateSR();
         break;
         
         case 87://w
            ClearAll();
            ShowSR_Weekly=!ShowSR_Weekly;
            Print("Weekly :", ShowSR_Weekly ? "on":"off");
            CalculateSR();
         break;
         
         case 68://d
            ClearAll();
            ShowSR_Daily=!ShowSR_Daily;
            Print("Daily :", ShowSR_Weekly ? "on":"off");
            CalculateSR();
         break;
         
         case 72://h
            ClearAll();
            ShowSR_4Hours=!ShowSR_4Hours;
            Print("4Hours :", ShowSR_Weekly ? "on":"off");
            CalculateSR();
         break;
         
         case 73://i
            ClearAll();
            ShowSR_1Hours=!ShowSR_1Hours;
            Print("1Hour :", ShowSR_1Hours ? "on":"off");
            CalculateSR();
         break;
         
         case 82://r
            ClearAll();
            ShowSR_1Hours=false;
            ShowSR_4Hours=false;
            ShowSR_Daily=true;
            ShowSR_Weekly=false;
            Detail=Medium;
            CalculateSR();
         break;
      }
   }
}