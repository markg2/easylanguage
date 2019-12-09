
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
	TextLabel myText(null),
	Font annotFont(null),
	IntrabarPersist lastBid(0),
	IntrabarPersist lastAsk(0),
	Dictionary dictBid(null),
	Dictionary dictAsk(null),
	IntrabarPersist int bidCumulative(0),
	IntrabarPersist int askCumulative(0);

Method Dictionary process(double argsPrice, int argsSize, Dictionary tsDict, TimeAndSalesItemTickType tickType)
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
					process(args.Data.Price, args.Data.Size, dictBid, TimeAndSalesItemTickType.Bid);
			 		process(args.Data.Price, 0, dictAsk, TimeAndSalesItemTickType.Bid);
					//plotVolume(bidCumulative, askCumulative, H);
				end;
				If price = lastAsk Then begin
					askCumulative = askCumulative + args.Data.Size;
					process(args.Data.Price, args.Data.Size, dictAsk,  TimeAndSalesItemTickType.Ask);
					process(args.Data.Price, 0, dictBid,  TimeAndSalesItemTickType.Ask);
					//plotVolume(bidCumulative, askCumulative, H);		
				end;
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

Method void plotVolume(int bidC, int askC, double strike)
Begin
	
	if bidC > askC then begin
		myText = TextLabel.Create(BNPoint.Create(BarNumber, strike + .1), numtostr(bidC - askC, 0));
//		myText.Font = annotFont;
		myText.Color = Color.Red;
		myText.Persist = true;		// persist keeps the text label on the chart between tick updates
		DrawingObjects.Add(myText);	// draws the text on the chart
	end
	else Begin
		myText = TextLabel.Create(BNPoint.Create(BarNumber, strike + .1), numtostr(askC - bidC, 0));
//		myText.Font = annotFont;
		myText.Color = Color.LightBlue;
		myText.Persist = true;		// persist keeps the text label on the chart between tick updates
		DrawingObjects.Add(myText);	// draws the text on the chart
	end;
		
end;

method void psp_updated( elsystem.Object sender, tsdata.marketdata.PriceSeriesUpdatedEventArgs args ) 
begin
	If args.Reason = PriceSeriesUpdateReason.BarClose Then
	Begin
		plotVolume(bidCumulative, askCumulative, 270.2);		

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


