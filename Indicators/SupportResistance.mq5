//+------------------------------------------------------------------+
//|                                            SupportResistance.mq4 |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//
// # Donations are welcome !!
// Like what you see ? Feel free to donate to support further developments..
// BTC: 1J4npABsiQa2GkJu5q6RsjtCR1jxNvZdtu
// BCC: 1J4npABsiQa2GkJu5q6RsjtCR1jxNvZdtu
// LTC: LN4BCwQEUzULg3z6NpA5KQSvUftv3xG9xA
// ETH: 0xfa77e81d94b39b49f4b3dc7880c68ad57e6e7163
// NEO: ANQxQxFd4z5c7P3W1azK7zxvzRNY4dwbJg
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property version   "1.01"
#property strict
#property indicator_chart_window


#include <CSupportResistance.mqh>


#ifdef __MQL4__

extern bool        SR_1Hours       = false;
extern bool        SR_4Hours       = false;
extern bool        SR_Daily        = false;
extern bool        SR_Weekly       = true;
extern bool        ShowAgeLabels   = true;
extern bool        ShowLastTouch   = false; 
extern bool        ShowAllSRLines  = false; 
extern string      __colors__      = "---- Colour settings ----";
extern color       ColorAge1       = clrSilver;
extern color       ColorAge2       = clrDarkGray;
extern color       ColorAge3       = clrLightSeaGreen;
extern color       ColorAge4       = clrTeal;
extern color       ColorText       = clrBlack;

#else

input  bool        i_SR_1Hours      = false;                               // Enable S&R on H1
input  bool        i_SR_4Hours      = false;                               // Enable S&R on H4
input  bool        i_SR_Daily       = false;                               // Enable S&R on D1
input  bool        i_SR_Weekly      = true;                                // Enable S&R on W1
input  bool        i_ShowAgeLabels  = true;                                // Show Age Labels
input  bool        i_ShowLastTouch  = false;                               // Show Last Touch
input  bool        i_ShowAllSRLines = false;                               // Show All S&R Lines
input  string      __colors__       = "---- Colour settings ----";         // COLOUR SETTINGS
input  color       ColorAge1        = clrSilver;                           // Colour for Age 1
input  color       ColorAge2        = clrDarkGray;                         // Colour for Age 2
input  color       ColorAge3        = clrLightSeaGreen;                    // Colour for Age 3
input  color       ColorAge4        = clrTeal;                             // Colour for Age 4
input  color       ColorText        = clrBlack;                            // Colour for Text Labels

bool               SR_1Hours        = i_SR_1Hours;
bool               SR_4Hours        = i_SR_4Hours;
bool               SR_Daily         = i_SR_Daily;
bool               SR_Weekly        = i_SR_Weekly;
bool               ShowAgeLabels    = i_ShowAgeLabels;
bool               ShowLastTouch    = i_ShowLastTouch;
bool               ShowAllSRLines   = i_ShowAllSRLines;

#endif


CSupportResistance* _supportResistanceW1;
CSupportResistance* _supportResistanceD1;
CSupportResistance* _supportResistanceH4;
CSupportResistance* _supportResistanceH1;


color        Colors[]     = { clrSilver, clrDarkGray, clrLightSeaGreen, clrTeal };


//+------------------------------------------------------------------+
void ClearAll()
{
   _supportResistanceW1.ClearAll();
   _supportResistanceD1.ClearAll();
   _supportResistanceH4.ClearAll();
   _supportResistanceH1.ClearAll();
}


//+------------------------------------------------------------------+
void CalculateSR(bool forceRefresh = false)
{  
   string txt="S/R:";
   if (SR_Weekly) 
   {
      txt +="W1,";
      _supportResistanceW1.Calculate(forceRefresh);
      _supportResistanceW1.Draw("W1", ColorText, Colors, ShowAgeLabels, ShowLastTouch, ShowAllSRLines);
   }
   
   if (SR_Daily) 
   {
      txt +="D1,";
      _supportResistanceD1.Calculate(forceRefresh);
      _supportResistanceD1.Draw("D1", ColorText, Colors, ShowAgeLabels, ShowLastTouch, ShowAllSRLines);
   }
   
   if (SR_4Hours)
   {
      txt +="H4,";
      _supportResistanceH4.Calculate(forceRefresh);
      _supportResistanceH4.Draw("H4", ColorText, Colors, ShowAgeLabels, ShowLastTouch, ShowAllSRLines);
   }
   
   if (SR_1Hours)
   {
      txt +="H1,";
      _supportResistanceH1.Calculate(forceRefresh);
      _supportResistanceH1.Draw("H1", ColorText, Colors, ShowAgeLabels, ShowLastTouch, ShowAllSRLines);
   }
   
   switch (SR_Detail)
   {
      case Minimum:    txt += " Minimum";     break;
      case MediumLow:  txt += " Medium/Low";  break;
      case Medium:     txt += " Medium";      break;
      case MediumHigh: txt += " Medium/High"; break;
      case Maximum:    txt += " Maximum";     break;
   }
   
#ifdef __MQL4__
   ObjectCreate("@info", OBJ_LABEL, 0, 0, 0);
   ObjectSet("@info", OBJPROP_BACK, false);
   ObjectSet("@info", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet("@info", OBJPROP_XDISTANCE, 250);
   ObjectSet("@info", OBJPROP_YDISTANCE, 0);
   ObjectSetText("@info", txt, 8, "Arial", ColorText);
#else
   ObjectCreate(ChartID(), "@info", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(ChartID(), "@info", OBJPROP_BACK, false);
   ObjectSetInteger(ChartID(), "@info", OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(ChartID(), "@info", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(ChartID(), "@info", OBJPROP_YDISTANCE, 0);
   
   ObjectSetString(ChartID(), "@info", OBJPROP_TEXT, txt);
   ObjectSetString(ChartID(), "@info", OBJPROP_FONT, "Arial");
   ObjectSetInteger(ChartID(), "@info", OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(ChartID(), "@info", OBJPROP_COLOR, ColorText);
   
   ChartRedraw(ChartID());
#endif
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
   CalculateSR();
   return(rates_total);
}


//+------------------------------------------------------------------+
#ifdef __MQL4__
void deinit()
#else
void OnDeinit(const int reason)
#endif
{ 
   ClearAll();
   delete _supportResistanceW1;
   delete _supportResistanceD1;
   delete _supportResistanceH4;
   delete _supportResistanceH1;
}


//+------------------------------------------------------------------+
#ifdef __MQL4__
int init()
#else
int OnInit()
#endif
{  
   Colors[0] = ColorAge1;
   Colors[1] = ColorAge2;
   Colors[2] = ColorAge3;
   Colors[3] = ColorAge4;
   
   _supportResistanceW1 = new CSupportResistance(Symbol(), PERIOD_W1);
   _supportResistanceD1 = new CSupportResistance(Symbol(), PERIOD_D1);
   _supportResistanceH4 = new CSupportResistance(Symbol(), PERIOD_H4);
   _supportResistanceH1 = new CSupportResistance(Symbol(), PERIOD_H1);
   
   CalculateSR(true);
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
void OnChartEvent(const int id,          // Event ID
                  const long& lparam,    // Parameter of type long event
                  const double& dparam,  // Parameter of type double event
                  const string& sparam)  // Parameter of type string events
{
   if (id == 9)
   {
      //Print("Chart zoomed or changed, recalculate SR");
      CalculateSR();
   }
   if (id == CHARTEVENT_KEYDOWN)
   {
      switch(lparam)
      {
         case 49://1
            Print("Detail: minimum");
            SR_Detail = Minimum;
            CalculateSR();
         break;
         
         case 50://2
            Print("Detail: medium low");
            SR_Detail = MediumLow; 
            CalculateSR();
         break;
         
         case 51://3
            Print("Detail: medium");
            SR_Detail = Medium; 
            CalculateSR();
         break;
         
         case 52://4
            Print("Detail: medium high");
            SR_Detail = MediumHigh; 
            CalculateSR();
         break;
         
         case 53://5
            Print("Detail: maximum");
            SR_Detail = Maximum; 
            CalculateSR();
         break;
         
         case 87://w
            ClearAll();
            SR_Weekly = !SR_Weekly;
            Print("Weekly :", SR_Weekly ? "on":"off");
            CalculateSR();
         break;
         
         case 65://a
            ClearAll();
            ShowAllSRLines = !ShowAllSRLines;
            Print("ShowAllSRLines :", ShowAllSRLines ? "on":"off");
            CalculateSR();
         break;
         
         case 68://d
            ClearAll();
            SR_Daily = !SR_Daily;
            Print("Daily :", SR_Weekly ? "on":"off");
            CalculateSR();
         break;
         
         case 72://h
            ClearAll();
            SR_4Hours = !SR_4Hours;
            Print("4Hours :", SR_Weekly ? "on":"off");
            CalculateSR();
         break;
         
         case 73://i
            ClearAll();
            SR_1Hours=!SR_1Hours;
            Print("1Hour :", SR_1Hours ? "on":"off");
            CalculateSR();
         break;
         
         case 82://r
            ClearAll();
            SR_1Hours = false;
            SR_4Hours = false;
            SR_Daily  = true;
            SR_Weekly = false;
            SR_Detail = Medium;
            CalculateSR();
         break;
      }
   }
}
