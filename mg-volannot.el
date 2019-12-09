
Using elsystem;
Using elsystem.collections;
Using elsystem.drawing;
Using tsdata.marketdata;



{ displays a rectangle containing a text label at a fixed position in a chart }

Using elsystem.drawingobjects;
Using elsystem.drawing;

Input: string iSymbol1( symbol );   { the test symbol }

var: 
	charting.ChartingHost ChartingHost1(NULL),
	TimeAndSalesProvider ts1(NULL),
	PriceSeriesProvider psp(NULL),
	TextLabel myText(null),		// declares a textlabel drawing object
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
					plotVolume(bidCumulative, askCumulative, H);
				end;
				If price = lastAsk Then begin
					askCumulative = askCumulative + args.Data.Size;
					process(args.Data.Price, args.Data.Size, dictAsk,  TimeAndSalesItemTickType.Ask);
					process(args.Data.Price, 0, dictBid,  TimeAndSalesItemTickType.Ask);
					plotVolume(bidCumulative, askCumulative, H);		
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
		myText.Color = Color.Red;
		myText.Persist = true;		// persist keeps the text label on the chart between tick updates
		DrawingObjects.Add(myText);	// draws the text on the chart
	end
	else Begin
		myText = TextLabel.Create(BNPoint.Create(BarNumber, strike + .1), numtostr(askC - bidC, 0));
		myText.Color = Color.Blue;
		myText.Persist = true;		// persist keeps the text label on the chart between tick updates
		DrawingObjects.Add(myText);	// draws the text on the chart
	end;
		
end;

method void psp_updated( elsystem.Object sender, tsdata.marketdata.PriceSeriesUpdatedEventArgs args ) 
begin
	If args.Reason = PriceSeriesUpdateReason.BarClose Then
	Begin
		dictAsk.Clear();
		dictBid.Clear();
		askCumulative = 0;
		bidCumulative = 0;
	end;
end;

method void psp_state_changed( elsystem.Object sender, tsdata.common.StateChangedEventArgs args ) 
begin

end;

{ plots the text rectangle when the chart window is initialized }
method void ChartingHost1_OnInitialUpdate( elsystem.Object sender, charting.OnInitialUpdateEventArgs args ) 
var: int bc;
begin
	PlotLabel(args.width,args.height);  // plots the text rectangle
end;

{ updates the text rectangle when the chart is resizsed }
method void ChartingHost1_OnSize( elsystem.Object sender, charting.OnSizeEventArgs args ) 
begin
	PlotLabel(args.width,args.height); // plots the text rectangle	
end;

{ plots a rectangle containing a text label near the upper right corner of a chart }
Method void PlotLabel(int ChartWidth, int ChartHeight) 
begin
	
	{create the rectangle and text drawing objects if they don't exist}
	If myText=null then begin
		myText = TextLabel.Create(BNPoint.Create(BarNumber, 270.8),"999");
		myText.Color = Color.White;
		myText.Persist = true;		// persist keeps the text label on the chart between tick updates
		DrawingObjects.Add(myText);	// draws the text on the chart

		myText = TextLabel.Create(BNPoint.Create(BarNumber-1, 270.8),"888");
		DrawingObjects.Add(myText);	// draws the text on the chart

		myText = TextLabel.Create(BNPoint.Create(BarNumber-2, 270.8),"777");
		DrawingObjects.Add(myText);	// draws the text on the chart

	end Else begin
		{udpates the X,Y coordinates for an existing rectangle and text}
		myText.PointValue=BNPoint.Create(BarNumber, 270);
		
	end;
end;

method override void InitializeComponent()
begin
		ChartingHost1 = new charting.ChartingHost;
		
		//---------------------------
		//chartinghost1
		//---------------------------
		ChartingHost1.Name = "ChartingHost1";
		
		//---------------------------
		//analysistechnique
		//---------------------------
		
		//--------------------------------------------
		//                  Events
		//--------------------------------------------
		ChartingHost1.oninitialupdate += chartinghost1_oninitialupdate;
		ChartingHost1.onsize += chartinghost1_onsize;

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

{updates the text string on every tick}
If myText<>null then myText.TextString = "333";


