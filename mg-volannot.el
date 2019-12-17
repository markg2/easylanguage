
Using elsystem;
Using elsystem.collections;
Using elsystem.drawing;
Using tsdata.marketdata;



{ displays a rectangle containing a text label at a fixed position in a chart }

Using elsystem.drawingobjects;
Using elsystem.drawing;

Input: string iSymbol1( symbol );   { the test symbol }

var: 
	TimeAndSalesProvider ts1(NULL),
	PriceSeriesProvider psp(NULL),
	TextLabel tBid(null),
	TextLabel tAsk(null),
	Font annotFont(null),
	IntrabarPersist lastBid(0),
	IntrabarPersist lastAsk(0),
	Dictionary dictBid(null),
	Dictionary dictAsk(null),
	IntrabarPersist int bidCumulative(0),
	IntrabarPersist int askCumulative(0),
	IntrabarPersist int pocIndex(1),
	IntrabarPersist int bidImbalanceCount(0),
	IntrabarPersist int askImbalanceCount(0)
	; 

Method Dictionary persistBidAsk(double argsPrice, int argsSize, Dictionary tsDict, TimeAndSalesItemTickType tickType)
var: int tradeVol, String keyPrice, int x, string calcValue;
Begin
	tradeVol = argsSize;
	try
		keyPrice = Numtostr(argsPrice, 2);
		if tsDict.Contains(keyPrice) Then 
		Begin
			Value1 = Strtonum(tsDict.Items[keyPrice].ToString());
			tradeVol += Value1;
			tsDict.Remove(keyPrice);
		end;
		tsDict.Add(keyPrice, tradeVol);
					
					
	Catch (elsystem.Exception ex)
	end;
	
	Return tsDict;

end;

method void ts1_updated( elsystem.Object sender, TimeAndSalesUpdatedEventArgs args ) 
Var: int type, double price;
begin
	If args.Reason = TimeAndSalesUpdateReason.Added Then
	begin
		type = args.Data.TickType;
		price = args.Data.Price;
		
		If type = TimeAndSalesItemTickType.Trade Then begin
			If args.Data.Size > 5 then
			Begin
				If price = lastBid Then begin
					bidCumulative = bidCumulative + args.Data.Size;
					persistBidAsk(args.Data.Price, args.Data.Size, dictBid, TimeAndSalesItemTickType.Bid);
			 		persistBidAsk(args.Data.Price, 0, dictAsk, TimeAndSalesItemTickType.Bid);
				end;
				If price = lastAsk Then begin
					askCumulative = askCumulative + args.Data.Size;
					persistBidAsk(args.Data.Price, args.Data.Size, dictAsk,  TimeAndSalesItemTickType.Ask);
					persistBidAsk(args.Data.Price, 0, dictBid,  TimeAndSalesItemTickType.Ask);
				end;
				calcHighsAndPoc(dictBid, dictAsk);
			end;
		end
		else if type = TimeAndSalesItemTickType.Ask Then begin
			lastAsk = price;
		end
		Else if type = TimeAndSalesItemTickType.Bid Then Begin
			lastBid = price;
		end;
		
		
	end ;
end;

Method void calcHighsAndPoc(Dictionary dictBid, Dictionary dictAsk)
var: 	string keyPrice, string calcValue,
		string calcValue2,
		int bidCount, int askCount, int highestCount,
		int x, int bidIndex, int askIndex,
		int pocVolHigh,
		int pocVolTemp,
		int counterAscending;

Begin
	bidCount = dictBid.Count;
	askCount = dictAsk.Count;
	highestCount = askCount;
	pocVolHigh = 0;
	pocVolTemp = 0;
	counterAscending = 1;
	bidImbalanceCount = 0;
	askImbalanceCount = 0;
	
	If bidCount > askCount Then highestCount = bidCount;
	x = highestCount;
	
	while x >= 0 Begin
		calcValue = "0";
		calcValue2 = "0";
		bidIndex = x + 1;
		askIndex = x;
		
		If bidIndex <= dictBid.Count And bidIndex > 0 Then Begin
			keyPrice = dictBid.Keys[bidIndex - 1].ToString();
			calcValue = dictBid.Items[keyPrice].ToString();
			bidImbalanceCount = bidImbalanceCount +
				imbalanceCount(dictBid.Items[keyPrice].ToString(), dictAsk.Items[keyPrice].ToString(), 1);
		end;

		If askIndex <= dictAsk.Count And askIndex > 0 Then Begin
			keyPrice = dictAsk.Keys[askIndex - 1].ToString();
			calcValue2 = dictAsk.Items[keyPrice].ToString();
			askImbalanceCount = askImbalanceCount +
				imbalanceCount(dictBid.Items[keyPrice].ToString(), dictAsk.Items[keyPrice].ToString(), 0);
		end;

		// point of control
		pocVolTemp = Strtonum(calcValue) + Strtonum(calcValue2);
		if pocVolTemp > pocVolHigh then Begin
		 	pocIndex = counterAscending;
	 		pocVolHigh = pocVolTemp;
	 		pocVolTemp = 0;
		end;

		x = x - 1;
		counterAscending = counterAscending + 1;
	end;
	
	// display point of control
	{
	if pocIndex < DataGridView1.Rows.CountTotal and pocIndex > 0 then begin
		row = DataGridView1.Rows.at(pocIndex);
		row.Cells[4].Value = "#";
	end;
	}	

end;

Method int imbalanceCount(String strBid, String strAsk, int isBid)
var: 	double quotient, int bid, int ask, int retval;
Begin
	retval = 0;
	bid = Strtonum(strBid);
	ask = Strtonum(strAsk);

	If isBid >= 1 And ask > 0 Then Begin
		quotient = bid/ask;
		If quotient > 4 Then retval = 1;
	end 
	else if isBid >= 1 and  bid >=400 then begin
		retval = 1;
	end;

	If isBid < 1 And bid > 0 Then Begin
		quotient = ask/bid;
		If quotient > 4 Then retval = 1;
	end 
	else if isBid < 1 and ask >=400 then begin
		retval = 1;
	end;
	
	return retval;
end;


Method void plotVolume(int bidC, int askC, double hStrike, double lStrike)
var: string imbalances;
Begin
	imbalances = numtostr(bidImbalanceCount, 0) + "x" + numtostr(askImbalanceCount, 0);

	if bidC > askC then begin
		tBid = TextLabel.Create(BNPoint.Create(BarNumber, lStrike), "-" + numtostr(bidC - askC, 0));
		tBid.Color = Color.Red;
		tBid.Persist = true;		// persist keeps the text label on the chart between tick updates
		DrawingObjects.Add(tBid);	// draws the text on the chart
		tAsk =  TextLabel.Create(BNPoint.Create(BarNumber, hStrike), imbalances);
		tAsk.Color = Color.Red;
		tAsk.Persist = true;
		DrawingObjects.Add(tAsk);
		
	end
	else Begin
		tAsk = TextLabel.Create(BNPoint.Create(BarNumber, hStrike), numtostr(askC - bidC, 0));
		tAsk.Color = Color.LightBlue;
		tAsk.Persist = true;		// persist keeps the text label on the chart between tick updates
		DrawingObjects.Add(tAsk);	// draws the text on the chart
		tBid =  TextLabel.Create(BNPoint.Create(BarNumber, lStrike), imbalances);
		tBid.Color = Color.LightBlue;
		tBid.Persist = true;
		DrawingObjects.Add(tBid);
	end;
		
end;

method void psp_updated( elsystem.Object sender, tsdata.marketdata.PriceSeriesUpdatedEventArgs args ) 
begin
	If args.Reason = PriceSeriesUpdateReason.BarClose Then
	Begin
		plotVolume(bidCumulative, askCumulative, H, L);		

		dictAsk.Clear();
		dictBid.Clear();
		askCumulative = 0;
		bidCumulative = 0;
	end;
end;

method void psp_state_changed( elsystem.Object sender, tsdata.common.StateChangedEventArgs args ) 
begin

end;

method override void InitializeComponent()
begin
		
	annotFont = Font.Create("Arial", 10);

	psp = new PriceSeriesProvider;
	psp.Interval.ChartType = tsdata.marketdata.DataChartType.Bars;
	psp.Interval.IntervalType = tsdata.marketdata.DataIntervalType.Minutes;
	psp.Interval.IntervalSpan = 1;
	psp.Interval.Name = "(Unknown name)";
	psp.Range.Type = tsdata.marketdata.DataRangeType.Bars;
	psp.Range.Name = "(Unknown name)";
	psp.IncludeVolumeInfo = false;
	psp.IncludeTicksInfo = false;
	psp.UseNaturalHours = false;
	psp.Realtime = true;
	psp.TimeZone = tsdata.common.TimeZone.local;
	psp.Name = "psp";
	psp.statechanged += psp_state_changed;
	psp.updated += psp_updated;
	psp.Symbol = "aapl";
	psp.Range.FirstDate = DateTime.FromELDateAndTime(D, T);
	psp.Load = true;

	ts1 = new TimeAndSalesProvider;
	ts1.Trades = true;
	ts1.Bids = true;
	ts1.Asks = true;
	ts1.DataFilterType = TimeAndSalesDataFilterType.TicksBack;
	ts1.TicksBack = 300;	
	ts1.Symbol = iSymbol1;
	ts1.TimeZone = tsdata.common.TimeZone.exchange;
	ts1.Load = True;
	ts1.Updated += ts1_updated;
		
	dictBid = New Dictionary;
	dictAsk = New Dictionary;

		//--------------------------------------------
		//                  Events
		//--------------------------------------------
		self.initialized += analysistechnique_initialized;
end;

// sample app is initializing
method void AnalysisTechnique_Initialized( elsystem.Object sender, elsystem.InitializedEventArgs args ) 
begin
end;


