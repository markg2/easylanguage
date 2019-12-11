Using elsystem;
Using elsystem.collections;
Using elsystem.windows.forms;
Using elsystem.drawing;
Using tsdata.marketdata;


Input: string iSymbol1( symbol );   { the test symbol }

var: 	elsystem.windows.forms.Form Form1(NULL), 
		elsystem.windows.forms.Panel PanelHeader(NULL),
		elsystem.windows.forms.Panel PanelBody(NULL),
		elsystem.windows.forms.Panel PanelFooter(NULL),
		elsystem.windows.forms.DataGridView DataGridView1(NULL),
		elsystem.windows.forms.Label Label1(NULL);
var: TimeAndSalesProvider ts1(NULL),
	PriceSeriesProvider psp(NULL),
	IntrabarPersist lastBid(0),
	IntrabarPersist lastAsk(0),
	Dictionary dictBid(null),
	Dictionary dictAsk(null),
	IntrabarPersist int bidCumulative(0),
	IntrabarPersist int askCumulative(0);


// sample app is initializing
method void AnalysisTechnique_Initialized( elsystem.Object sender, elsystem.InitializedEventArgs args ) 
begin
	FillGrid(); // add new column types
	Form1.Show(); // show the form in the tradingapp
end;

// populate the datagridview
Method void FillGrid()
Vars:  	DataGridViewButtonColumn btncol, DataGridViewCheckBoxColumn chkboxcol, DataGridViewComboBoxColumn comboxcol, 
		DataGridViewDateTimePickerColumn dtpcol, DataGridViewLinkColumn lcol, 
		DataGridViewNumericUpDownColumn nudcol, DataGridViewColumn col;

Begin
	// add a string column
	col = DataGridViewColumn.Create("bVol");
	col.SortMode = DataGridViewColumnSortMode.Automatic;	
	col.ReadOnly = True;	
	DataGridView1.Columns.Add(col);

	col = DataGridViewColumn.Create("bStrike");
	col.SortMode = DataGridViewColumnSortMode.Automatic;	
	col.ReadOnly = True;	
	DataGridView1.Columns.Add(col);

	col = DataGridViewColumn.Create("aStrike");
	col.SortMode = DataGridViewColumnSortMode.Automatic;	
	col.ReadOnly = True;	
	DataGridView1.Columns.Add(col);
	
	// add a number column
	col = DataGridViewColumn.Create("aVol");
	col.SortMode = DataGridViewColumnSortMode.Automatic;
	col.ReadOnly = True;
	DataGridView1.Columns.Add(col);
	
End;

// use has selected or deselected a cell
method void DataGridView1_SelectionChanged( elsystem.Object sender, elsystem.EventArgs args ) 
begin
	Print("Selection Changed: ", DataGridView1.SelectedCells.Count, " cells are selected");
end;

// user clicked in a cell
method void DataGridView1_CellClick( elsystem.Object sender, elsystem.windows.forms.DataGridViewCellEventArgs args ) 
begin
	Print("CellClick: Row = ", args.RowIndex, " Column = ", args.ColumnIndex); 

	// if clicking on button, use the selected grid display style
	If (args.ColumnIndex = 0 and args.RowIndex >= 0) then
	Begin
		Print(DataGridView1.Rows[args.RowIndex].Cells[0].Text, " Clicked");
	End;
end;

// cell value changing
method void DataGridView1_CellValueChanged( elsystem.Object sender, elsystem.windows.forms.DataGridViewCellEventArgs args ) 
begin
	Print("CellValueChanged: Row = ", args.RowIndex, " Column = ", args.ColumnIndex); 
end;

// user clicking in column header
method void DataGridView1_ColumnHeaderMouseClick( elsystem.Object sender, elsystem.windows.forms.DataGridViewCellMouseEventArgs args ) 
begin
	Print("ColumnHeaderMouseClick: Row = ", args.RowIndex, " Column = ", args.ColumnIndex); 
end;

// user clicking in row header
method void DataGridView1_RowHeaderMouseClick( elsystem.Object sender, elsystem.windows.forms.DataGridViewCellMouseEventArgs args ) 
begin
	Print("RowHeaderMouseClick: Row = ", args.RowIndex, " Column = ", args.ColumnIndex); 
end;

// sort is taking place, two cells are being compared
method void DataGridView1_SortCompare( elsystem.Object sender, elsystem.windows.forms.DataGridViewSortCompareEventArgs args ) 
begin
	Print("SortCompare: Row1 = ", args.RowIndex1, " Value1 = ", args.CellValue1.ToString(),  " Row2 = ", args.RowIndex2, " Value2 = ", args.CellValue2.ToString()); 
end;

Method void showAll(Dictionary dictBid, Dictionary dictAsk)
var: 		DataGridViewRow row, string keyPrice, string calcValue,
		int bidCount, int askCount, int highestCount,
		int x, int bidIndex, int askIndex;

Begin
	bidCount = dictBid.Count;
	askCount = dictAsk.Count;
	highestCount = askCount;
	x = highestCount;
	
	If bidCount > askCount Then highestCount = bidCount;
	
	while x >= 0 Begin
		row = DataGridViewRow.Create("");
		DataGridView1.Rows.Add(row);	
		bidIndex = x + 1;
		askIndex = x;
		
		If bidIndex <= dictBid.Count And bidIndex > 0 Then Begin
			keyPrice = dictBid.Keys[bidIndex - 1].ToString();
			calcValue = dictBid.Items[keyPrice].ToString();
			row.Cells[0].Value = calcValue;
//			row.Cells[0].BackColor = elsystem.drawing.Color.LightCoral;
			colorForeground(dictBid.Items[keyPrice].ToString(), dictAsk.Items[keyPrice].ToString(), 1, 0, row);
			row.Cells[1].Value = keyPrice;
		end;

		If askIndex <= dictAsk.Count And askIndex > 0 Then Begin
			keyPrice = dictAsk.Keys[askIndex - 1].ToString();
			calcValue = dictAsk.Items[keyPrice].ToString();
			row.Cells[2].Value = keyPrice;
			row.Cells[3].Value = calcValue;
			colorForeground(dictBid.Items[keyPrice].ToString(), dictAsk.Items[keyPrice].ToString(), 0, 3, row);
//			row.Cells[3].BackColor = elsystem.drawing.Color.LightBlue;
		end;

		x = x - 1;
	end;

end;

Method void colorForeground(String strBid, String strAsk, int isBid, int cellIndex, DataGridViewRow row)
var: 	double quotient, int bid, int ask;
Begin
	bid = Strtonum(strBid);
	ask = Strtonum(strAsk);

	If isBid >= 1 And ask > 0 Then Begin
		quotient = bid/ask;
		If quotient > 3 Then row.Cells[cellIndex].ForeColor = elsystem.drawing.Color.Red;
	end 
	else if isBid >= 1 and  bid >=300 then begin
		row.Cells[cellIndex].ForeColor = elsystem.drawing.Color.Red;
	end;

	If isBid < 1 And bid > 0 Then Begin
		quotient = ask/bid;
		If quotient > 3 Then row.Cells[cellIndex].ForeColor = elsystem.drawing.Color.Blue;
	end 
	else if isBid < 1 and ask >=300 then begin
		row.Cells[cellIndex].ForeColor = elsystem.drawing.Color.Blue;
	end;
	
end;

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
Var: int type, double price, double bidAskRatio;

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
				end;
				If price = lastAsk Then begin
					askCumulative = askCumulative + args.Data.Size;
					process(args.Data.Price, args.Data.Size, dictAsk,  TimeAndSalesItemTickType.Ask);
					process(args.Data.Price, 0, dictBid,  TimeAndSalesItemTickType.Ask);
				end;
				DataGridView1.Rows.Clear();	
				showAll(dictBid, dictAsk);
			end;
		end
		else if type = TimeAndSalesItemTickType.Ask Then begin
			lastAsk = price;
		end
		Else if type = TimeAndSalesItemTickType.Bid Then Begin
			lastBid = price;
		end;
		
		bidAskRatio = 0.1;
		if bidCumulative > askCumulative then begin
			if askCumulative > 0 then bidAskRatio = bidCumulative/askCumulative;
			Label1.BackColor = elsystem.drawing.Color.Red;
			Label1.ForeColor = elsystem.drawing.Color.White;
			Label1.Text = Numtostr(bidAskRatio, 1) + " (" + Numtostr(bidCumulative-askCumulative, 0) + ")";
//			Label1.Text = Numtostr(bidAskRatio, 1);
		end
		else Begin
			if bidCumulative > 0 then bidAskRatio = askCumulative/bidCumulative;
			Label1.BackColor = elsystem.drawing.Color.LightBlue;
			Label1.ForeColor = elsystem.drawing.Color.Black;
			Label1.Text = Numtostr(bidAskRatio, 1) + " (" + Numtostr(askCumulative-bidCumulative, 0) + ")";
//			Label1.Text = Numtostr(bidAskRatio, 1);
		end;

	end ;
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

method override void InitializeComponent()
begin
		Form1 = new elsystem.windows.forms.Form();
		DataGridView1 = new elsystem.windows.forms.DataGridView();
		Label1 = elsystem.windows.forms.Label.Create("bid/ask VOL", 100, 20);
		PanelHeader = elsystem.windows.forms.Panel.Create(400, 20);
		PanelBody = elsystem.windows.forms.Panel.Create(400, 600);
		PanelFooter = elsystem.windows.forms.Panel.Create(400, 20);

		PanelHeader.AddControl(Label1);		
		PanelBody.AddControl(DataGridView1);
		
		//---------------------------
		//form1
		//---------------------------
		Form1.RightToLeftLayout = false;
		Form1.FormBorderStyle = elsystem.windows.forms.FormBorderStyle.Sizable;
		Form1.ControlBox = true;
		Form1.Text = "DataGridView Sample";
		Form1.Width = 300;
		Form1.Height = 472;
		Form1.Dock = elsystem.windows.forms.DockStyle.Right;
		Form1.Enabled = true;
		Form1.BackColor = elsystem.drawing.Color.FromArgb(240, 240, 240);
		Form1.ForeColor = elsystem.drawing.Color.Black;
		Form1.Margin = new elsystem.windows.forms.Padding( 3, 3, 3, 3 );
		Form1.Font = elsystem.drawing.Font.Create("Microsoft Sans Serif", 8.25, 0);
		Form1.ControlLocation.X = 574;
		Form1.ControlLocation.Y = 0;
		Form1.Controls.Add(PanelHeader);
		Form1.Controls.Add(PanelBody);
		Form1.RightToLeft = elsystem.windows.forms.RightToLeft.No;
		Form1.Name = "Form1";

		PanelHeader.Location(150,10);
		PanelBody.Location(0, 40);

		// Summary
		Label1.Location(0, 0);
		
		
		//---------------------------
		//datagridview1
		//---------------------------
		DataGridView1.Location(0, 300);
		DataGridView1.GridColor = elsystem.drawing.Color.FromArgb(160, 160, 160);
		DataGridView1.BorderStyle = elsystem.windows.forms.BorderStyle.FixedSingle;
		DataGridView1.GradientMode = elsystem.windows.forms.LinearGradientMode.ForwardDiagonal;
		DataGridView1.ColumnHeadersHeight = 23;
		DataGridView1.RowHeadersWidth = 41;
		DataGridView1.RowHeadersVisible = true;
		DataGridView1.RowHeadersFont = elsystem.drawing.Font.Create("Microsoft Sans Serif", 8.25, 0);
		DataGridView1.ColumnHeadersVisible = true;
		DataGridView1.ColumnHeadersFont = elsystem.drawing.Font.Create("Microsoft Sans Serif", 8.25, 0);
		DataGridView1.AllowUserToAddRows = false;
		DataGridView1.CellBorderStyle = elsystem.windows.forms.DataGridViewCellBorderStyle.Single;
		DataGridView1.RowHeadersBorderStyle = elsystem.windows.forms.DataGridViewHeaderBorderStyle.Raised;
		DataGridView1.ColumnHeadersBorderStyle = elsystem.windows.forms.DataGridViewHeaderBorderStyle.Raised;
		DataGridView1.ReadOnly = false;
		DataGridView1.SelectionMode = elsystem.windows.forms.DataGridViewSelectionMode.CellSelect;
		DataGridView1.MultiSelect = true;
		DataGridView1.DefaultCellStyle.Alignment = elsystem.windows.forms.DataGridViewContentAlignment.MiddleLeft;
		DataGridView1.DefaultCellStyle.BackColor = elsystem.drawing.SystemColors.Window;
		DataGridView1.DefaultCellStyle.Font = elsystem.drawing.Font.Create("Microsoft Sans Serif", 8.25, 0);
		DataGridView1.DefaultCellStyle.ForeColor = elsystem.drawing.Color.Black;
		DataGridView1.DefaultCellStyle.SelectionBackColor = elsystem.drawing.SystemColors.Highlight;
		DataGridView1.DefaultCellStyle.SelectionForeColor = elsystem.drawing.SystemColors.HighlightText;
		DataGridView1.DefaultCellStyle.WrapMode = elsystem.windows.forms.DataGridViewTriState.False;
		DataGridView1.AlternatingRowsDefaultCellStyle.Alignment = elsystem.windows.forms.DataGridViewContentAlignment.NotSet;
		DataGridView1.AlternatingRowsDefaultCellStyle.Font = elsystem.drawing.Font.Create("Microsoft Sans Serif", 8.00, 0);
		DataGridView1.AlternatingRowsDefaultCellStyle.WrapMode = elsystem.windows.forms.DataGridViewTriState.NotSet;
		DataGridView1.EnableHeadersVisualStyles = true;
		DataGridView1.RowHeadersDefaultCellStyle.Alignment = elsystem.windows.forms.DataGridViewContentAlignment.MiddleLeft;
		DataGridView1.RowHeadersDefaultCellStyle.BackColor = elsystem.drawing.SystemColors.Control;
		DataGridView1.RowHeadersDefaultCellStyle.Font = elsystem.drawing.Font.Create("Microsoft Sans Serif", 8.25, 0);
		DataGridView1.RowHeadersDefaultCellStyle.ForeColor = elsystem.drawing.SystemColors.WindowText;
		DataGridView1.RowHeadersDefaultCellStyle.SelectionBackColor = elsystem.drawing.SystemColors.Highlight;
		DataGridView1.RowHeadersDefaultCellStyle.SelectionForeColor = elsystem.drawing.SystemColors.HighlightText;
		DataGridView1.RowHeadersDefaultCellStyle.WrapMode = elsystem.windows.forms.DataGridViewTriState.True;
		DataGridView1.ColumnHeadersDefaultCellStyle.Alignment = elsystem.windows.forms.DataGridViewContentAlignment.MiddleLeft;
		DataGridView1.ColumnHeadersDefaultCellStyle.BackColor = elsystem.drawing.SystemColors.Control;
		DataGridView1.ColumnHeadersDefaultCellStyle.Font = elsystem.drawing.Font.Create("Microsoft Sans Serif", 8.25, 0);
		DataGridView1.ColumnHeadersDefaultCellStyle.ForeColor = elsystem.drawing.SystemColors.WindowText;
		DataGridView1.ColumnHeadersDefaultCellStyle.SelectionBackColor = elsystem.drawing.SystemColors.Highlight;
		DataGridView1.ColumnHeadersDefaultCellStyle.SelectionForeColor = elsystem.drawing.SystemColors.HighlightText;
		DataGridView1.ColumnHeadersDefaultCellStyle.WrapMode = elsystem.windows.forms.DataGridViewTriState.True;
		DataGridView1.Text = "DataGridView1";
		DataGridView1.Width = 284;
		DataGridView1.Height = 434;
		DataGridView1.Dock = elsystem.windows.forms.DockStyle.Fill;
		DataGridView1.Enabled = true;
		DataGridView1.BackColor = elsystem.drawing.Color.FromArgb(171, 171, 171);
		DataGridView1.ForeColor = elsystem.drawing.Color.Black;
		DataGridView1.Margin = new elsystem.windows.forms.Padding( 3, 3, 3, 3 );
		DataGridView1.Font = elsystem.drawing.Font.Create("Microsoft Sans Serif", 8.25, 0);
//		DataGridView1.ControlLocation.X = 0;
//		DataGridView1.ControlLocation.Y = 100;
		DataGridView1.RightToLeft = elsystem.windows.forms.RightToLeft.No;
		DataGridView1.Name = "DataGridView1";
		

		
		//---------------------------
		//analysistechnique
		//---------------------------
		
		//--------------------------------------------
		//                  Events
		//--------------------------------------------
		DataGridView1.cellclick += datagridview1_cellclick;
		DataGridView1.cellvaluechanged += datagridview1_cellvaluechanged;
		DataGridView1.columnheadermouseclick += datagridview1_columnheadermouseclick;
		DataGridView1.rowheadermouseclick += datagridview1_rowheadermouseclick;
		DataGridView1.selectionchanged += datagridview1_selectionchanged;
		DataGridView1.sortcompare += datagridview1_sortcompare;
		
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