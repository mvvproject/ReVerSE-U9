// Keyboard matrix module
// Modify for Spetsialist by Ewgeny7 & Fifan

`default_nettype none
module spetskeyboard
(
input		clk,							// синхронизация
input		reset,						// вход сброса
inout		ps2_clk,						// синхронизация PS/2 клавиатуры
inout		ps2_data,					// данные PS/2 клавиатуры
input		[3:0]		hardware_keys,

input    metod,						// метод сканирования клавиатуры
input		mode,							// режим работы "МХ / Стандарт"
input		rus_lat,						// режим клавиатуры "РУС / LAT"
input		[11:0]	sp_kb_scan,		// сканируемый код
output	[11:0]	sp_kb_out,		// код ответа		

output   	res_k,					// reset button K[3]
output		key_ss,					// клавиша "НР" нажата (SHIFT)
output   	test_k,					// клавиша теста (K[0])
output   	ruslat_k,				// клавиша "РУС / LAT" (ALT)
output		turbo_k,					// сигнал "турбо/нормал" (K[1])
output   	mx_k						// клавиша "МХ / Стандарт" (K[2])
);

// low-level ps/2 keyboard reader
// scancode[9] - ext key, pressrelease - release state
reg scancode_ready;
reg[9:0] scancode;
Keyboard kbd(
	.Clock(clk),
	.Reset(reset),
	.PS2Clock(ps2_clk),
	.PS2Data(ps2_data),
	.CodeReady(scancode_ready),
	.ScanCode(scancode)
);

////////////////////   RESET   ////////////////////                                                                                                                       
reg[3:0] res_cnt;
reg res_key;
assign res_k = ~res_key;                                                                                                                                                      
                                                                                                                                                                          
always @(posedge clk) begin                                                                                                                                          
        if (hardware_keys[3] && res_cnt==4'd14)                                                                                                                                   
                res_key <= 1'b1;                                                                                                                                          
        else begin                                                                                                                                                        
                res_key <= 1'b0;                                                                                                                                          
                res_cnt <= res_cnt+4'd1;                                                                                                                              
        end                                                                                                                                                               
end

// TODO: other button K0 - K2 here

// turbo key
reg		turbo_key = 1'b0;
assign	turbo_k = turbo_key;

// mx state key
reg     	mx_st_key = 1'b0;
reg 		mx_st;
assign   mx_k = mx_st_key;

// test key
reg     	test_key = 1'b0;
reg 		test;
assign   test_k = test_key;

// rl key
reg     	rl_key = 1'b0;
reg 		rl_st;
assign   ruslat_k = rl_key;

// shift key
reg		shift;
assign	key_ss = shift;


// при mode=1 нужно:
// при metod=1 - вывод "все нули" на 12 выходов, ответ на 6 входов
// при metod=0 - вывод на 6 выходов, ответ на 12 входов

reg			[11:0]	sp_kb_out_;
assign		sp_kb_out = sp_kb_out_;		

reg			[3:0] 	col;
reg			[5:0]		keymatrixa[0:11];
wire			[0:11] 	keymatrixb[5:0];

assign 		keymatrixb[0][0] = keymatrixa[11][5];
assign 		keymatrixb[0][1] = keymatrixa[10][5];
assign 		keymatrixb[0][2] = keymatrixa[9][5];
assign 		keymatrixb[0][3] = keymatrixa[8][5];
assign 		keymatrixb[0][4] = keymatrixa[7][5];
assign 		keymatrixb[0][5] = keymatrixa[6][5];
assign 		keymatrixb[0][6] = keymatrixa[5][5];
assign 		keymatrixb[0][7] = keymatrixa[4][5];
assign 		keymatrixb[0][8] = keymatrixa[3][5];
assign 		keymatrixb[0][9] = keymatrixa[2][5];
assign 		keymatrixb[0][10] = keymatrixa[1][5];
assign 		keymatrixb[0][11] = keymatrixa[0][5];

assign 		keymatrixb[1][0] = keymatrixa[11][4];
assign 		keymatrixb[1][1] = keymatrixa[10][4];
assign 		keymatrixb[1][2] = keymatrixa[9][4];
assign 		keymatrixb[1][3] = keymatrixa[8][4];
assign 		keymatrixb[1][4] = keymatrixa[7][4];
assign 		keymatrixb[1][5] = keymatrixa[6][4];
assign 		keymatrixb[1][6] = keymatrixa[5][4];
assign 		keymatrixb[1][7] = keymatrixa[4][4];
assign 		keymatrixb[1][8] = keymatrixa[3][4];
assign 		keymatrixb[1][9] = keymatrixa[2][4];
assign 		keymatrixb[1][10] = keymatrixa[1][4];
assign 		keymatrixb[1][11] = keymatrixa[0][4];

assign 		keymatrixb[2][0] = keymatrixa[11][3];
assign 		keymatrixb[2][1] = keymatrixa[10][3];
assign 		keymatrixb[2][2] = keymatrixa[9][3];
assign 		keymatrixb[2][3] = keymatrixa[8][3];
assign 		keymatrixb[2][4] = keymatrixa[7][3];
assign 		keymatrixb[2][5] = keymatrixa[6][3];
assign 		keymatrixb[2][6] = keymatrixa[5][3];
assign 		keymatrixb[2][7] = keymatrixa[4][3];
assign 		keymatrixb[2][8] = keymatrixa[3][3];
assign 		keymatrixb[2][9] = keymatrixa[2][3];
assign 		keymatrixb[2][10] = keymatrixa[1][3];
assign 		keymatrixb[2][11] = keymatrixa[0][3];

assign 		keymatrixb[3][0] = keymatrixa[11][2];
assign 		keymatrixb[3][1] = keymatrixa[10][2];
assign 		keymatrixb[3][2] = keymatrixa[9][2];
assign 		keymatrixb[3][3] = keymatrixa[8][2];
assign 		keymatrixb[3][4] = keymatrixa[7][2];
assign 		keymatrixb[3][5] = keymatrixa[6][2];
assign 		keymatrixb[3][6] = keymatrixa[5][2];
assign 		keymatrixb[3][7] = keymatrixa[4][2];
assign 		keymatrixb[3][8] = keymatrixa[3][2];
assign 		keymatrixb[3][9] = keymatrixa[2][2];
assign 		keymatrixb[3][10] = keymatrixa[1][2];
assign 		keymatrixb[3][11] = keymatrixa[0][2];

assign 		keymatrixb[4][0] = keymatrixa[11][1];
assign 		keymatrixb[4][1] = keymatrixa[10][1];
assign 		keymatrixb[4][2] = keymatrixa[9][1];
assign 		keymatrixb[4][3] = keymatrixa[8][1];
assign 		keymatrixb[4][4] = keymatrixa[7][1];
assign 		keymatrixb[4][5] = keymatrixa[6][1];
assign 		keymatrixb[4][6] = keymatrixa[5][1];
assign 		keymatrixb[4][7] = keymatrixa[4][1];
assign 		keymatrixb[4][8] = keymatrixa[3][1];
assign 		keymatrixb[4][9] = keymatrixa[2][1];
assign 		keymatrixb[4][10] = keymatrixa[1][1];
assign 		keymatrixb[4][11] = keymatrixa[0][1];

assign 		keymatrixb[5][0] = keymatrixa[11][0];
assign 		keymatrixb[5][1] = keymatrixa[10][0];
assign 		keymatrixb[5][2] = keymatrixa[9][0];
assign 		keymatrixb[5][3] = keymatrixa[8][0];
assign 		keymatrixb[5][4] = keymatrixa[7][0];
assign 		keymatrixb[5][5] = keymatrixa[6][0];
assign 		keymatrixb[5][6] = keymatrixa[5][0];
assign 		keymatrixb[5][7] = keymatrixa[4][0];
assign 		keymatrixb[5][8] = keymatrixa[3][0];
assign 		keymatrixb[5][9] = keymatrixa[2][0];
assign 		keymatrixb[5][10] = keymatrixa[1][0];
assign 		keymatrixb[5][11] = keymatrixa[0][0];

//always@ (posedge mx_st) mx_st_key <= (~mx_st_key);

//always@ (posedge test) test_key <= (~test_key);

//always@ (posedge rl_st) rl_key <= (~rl_key);

always 
	begin
		if (mode == 1'b0) 
			begin
			if (metod == 1'b0) 	
				begin
				sp_kb_out_ = ~({6'h0,   ((sp_kb_scan[0]==1'b0)? keymatrixa[0]: 6'h0) |
										((sp_kb_scan[1]==1'b0)? keymatrixa[1]: 6'h0) |
										((sp_kb_scan[2]==1'b0)? keymatrixa[2]: 6'h0) |
										((sp_kb_scan[3]==1'b0)? keymatrixa[3]: 6'h0) |
										((sp_kb_scan[4]==1'b0)? keymatrixa[4]: 6'h0) |
										((sp_kb_scan[5]==1'b0)? keymatrixa[5]: 6'h0) |
										((sp_kb_scan[6]==1'b0)? keymatrixa[6]: 6'h0) |
										((sp_kb_scan[7]==1'b0)? keymatrixa[7]: 6'h0) |
										((sp_kb_scan[8]==1'b0)? keymatrixa[8]: 6'h0) |
										((sp_kb_scan[9]==1'b0)? keymatrixa[9]: 6'h0) |
										((sp_kb_scan[10]==1'b0)? keymatrixa[10]: 6'h0) |
										((sp_kb_scan[11]==1'b0)? keymatrixa[11]: 6'h0) });
				end
			else 				
				begin
				sp_kb_out_ = ~( ((sp_kb_scan[0]==1'b0)? keymatrixb[5]: 12'h0) |
								((sp_kb_scan[1]==1'b0)? keymatrixb[4]: 12'h0) |
								((sp_kb_scan[2]==1'b0)? keymatrixb[3]: 12'h0) |
								((sp_kb_scan[3]==1'b0)? keymatrixb[2]: 12'h0) |
								((sp_kb_scan[4]==1'b0)? keymatrixb[1]: 12'h0) |
								((sp_kb_scan[5]==1'b0)? keymatrixb[0]: 12'h0) );
				end
			end
		else			
			begin
//		режим МХ
			if (metod == 1'b0) 
				begin
// режим 0 - опрос - посылка 12 нулей, ответ 6 линий, если хоть один 0, то переход на режим 1
				sp_kb_out_ = ~({6'h0,   ((sp_kb_scan[0]==1'b0)? keymatrixa[0]: 6'h0) |
										((sp_kb_scan[1]==1'b0)? keymatrixa[1]: 6'h0) |
										((sp_kb_scan[2]==1'b0)? keymatrixa[2]: 6'h0) |
										((sp_kb_scan[3]==1'b0)? keymatrixa[3]: 6'h0) |
										((sp_kb_scan[4]==1'b0)? keymatrixa[4]: 6'h0) |
										((sp_kb_scan[5]==1'b0)? keymatrixa[5]: 6'h0) |
										((sp_kb_scan[6]==1'b0)? keymatrixa[6]: 6'h0) |
										((sp_kb_scan[7]==1'b0)? keymatrixa[7]: 6'h0) |
										((sp_kb_scan[8]==1'b0)? keymatrixa[8]: 6'h0) |
										((sp_kb_scan[9]==1'b0)? keymatrixa[9]: 6'h0) |
										((sp_kb_scan[10]==1'b0)? keymatrixa[10]: 6'h0) |
										((sp_kb_scan[11]==1'b0)? keymatrixa[11]: 6'h0) });
				end
			else			
				begin
// режим 1 - ответ клавиатуры - 12 линий
				sp_kb_out_ = ~( ((sp_kb_scan[0]==1'b0)? keymatrixb[5]: 12'h0) |
								((sp_kb_scan[1]==1'b0)? keymatrixb[4]: 12'h0) |
								((sp_kb_scan[2]==1'b0)? keymatrixb[3]: 12'h0) |
								((sp_kb_scan[3]==1'b0)? keymatrixb[2]: 12'h0) |
								((sp_kb_scan[4]==1'b0)? keymatrixb[1]: 12'h0) |
								((sp_kb_scan[5]==1'b0)? keymatrixb[0]: 12'h0) );	
				end
		end
end					

wire pressrelease;
assign pressrelease = ~scancode[8];

always	@(posedge clk)
begin
	if (reset)
			begin
			keymatrixa[0] <= 6'h00;
			keymatrixa[1] <= 6'h00;
			keymatrixa[2] <= 6'h00;
			keymatrixa[3] <= 6'h00;
			keymatrixa[4] <= 6'h00;
			keymatrixa[5] <= 6'h00;
			keymatrixa[6] <= 6'h00;
			keymatrixa[7] <= 6'h00;
			keymatrixa[8] <= 6'h00;
			keymatrixa[9] <= 6'h00;
			keymatrixa[10] <= 6'h00;
			keymatrixa[11] <= 6'h00;			
			end
	else
		begin
			if (scancode_ready) begin
						case ({scancode[9],scancode[7:0]})

							9'h005: begin
								if (mx_st_key == 1'b0) 
									keymatrixa[11][5]	<= pressrelease; //F1
								else
									keymatrixa[9][5]	<= pressrelease; //F1
								end
								
							9'h006: begin
								if (mx_st_key == 1'b0) 
									keymatrixa[10][5] 	<= pressrelease; //F2
								else
									keymatrixa[8][5]	<= pressrelease; //F2
								end
								
							9'h004:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[9][5]	<= pressrelease; //F3
								else
									keymatrixa[7][5]	<= pressrelease; //F3
								end
								
							9'h00c:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[8][5]	<= pressrelease; //F4
								else
									keymatrixa[6][5]	<= pressrelease; //F4
								end
								
							9'h003:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[7][5]	<= pressrelease; //F5
								else
									keymatrixa[5][5]	<= pressrelease; //F5
								end
								
							9'h00b:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[6][5]	<= pressrelease; //F6
								else
									keymatrixa[4][5]	<= pressrelease; //F6
								end
								
							9'h083:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[5][5]	<= pressrelease; //F7
								else
									keymatrixa[3][5]	<= pressrelease; //F7
								end
								
							9'h00a:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[4][5]	<= pressrelease; //F8
								else
									keymatrixa[2][5]	<= pressrelease; //F8
								end
								
							9'h001:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[3][5]	<= pressrelease; //F9
								else
									keymatrixa[1][5] 	<= pressrelease; //F9
								end
														
							9'h009:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[2][5]	<= pressrelease; //ЧФ
								else
									keymatrixa[10][5] 	<= pressrelease; //КОИ
								end								
								
							9'h078:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[1][5]	<= pressrelease; //БФ
								else
									keymatrixa[0][5] 	<= pressrelease; //СТР
								end									

							9'h007:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[0][5] 	<= pressrelease; //СТР
								end	

							9'h079:	begin 
										shift <= pressrelease;
										keymatrixa[11][4]   <= pressrelease; //;
									end	
							9'h016:	keymatrixa[10][4]	<= pressrelease; //1
							9'h01e:	keymatrixa[9][4]	<= pressrelease; //2
							9'h026:	keymatrixa[8][4]	<= pressrelease; //3
							9'h025:	keymatrixa[7][4]	<= pressrelease; //4
							9'h02e:	keymatrixa[6][4]	<= pressrelease; //5
							9'h036:	keymatrixa[5][4]	<= pressrelease; //6
							9'h03d:	keymatrixa[4][4]	<= pressrelease; //7
							9'h03e:	keymatrixa[3][4]	<= pressrelease; //8
							9'h046:	keymatrixa[2][4]	<= pressrelease; //9
							9'h045:	keymatrixa[1][4] 	<= pressrelease; //0
							9'h04e:	keymatrixa[0][4] 	<= pressrelease; //=
							9'h07b:	keymatrixa[0][4] 	<= pressrelease; //=
							
							9'h070: keymatrixa[1][4]	<= pressrelease; // 0
							9'h069:	keymatrixa[10][4]	<= pressrelease; // 1
							9'h072:	keymatrixa[9][4]	<= pressrelease; // 2
							9'h07a:	keymatrixa[8][4]	<= pressrelease; // 3
							9'h06b:	keymatrixa[7][4]	<= pressrelease; // 4
							9'h073:	keymatrixa[6][4]	<= pressrelease; // 5
							9'h074:	keymatrixa[5][4]	<= pressrelease; // 6
							9'h06c:	keymatrixa[4][4]	<= pressrelease; // 7
							9'h075:	keymatrixa[3][4]	<= pressrelease; // 8
							9'h07d:	keymatrixa[2][4]	<= pressrelease; // 9
							
							9'h00e:	keymatrixa[10][1]	<= pressrelease; // /\							
							
							9'h015:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[11][1]	<= pressrelease; //Q
								else
									keymatrixa[11][3]	<= pressrelease; //Й
								end
								
							9'h01d:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[9][2]	<= pressrelease; //W
								else
									keymatrixa[10][3]	<= pressrelease; //Ц
								end

							9'h024:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[7][3]	<= pressrelease; //E
								else
									keymatrixa[9][3]	<= pressrelease; //У
								end
								
							9'h02d:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[6][2]	<= pressrelease; //R
								else
									keymatrixa[8][3]	<= pressrelease; //К
								end									

							9'h02c:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[6][1]	<= pressrelease; //T
								else
									keymatrixa[7][3]	<= pressrelease; //Е
								end
								
							9'h035:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[10][2]	<= pressrelease; //Y
								else
									keymatrixa[6][3]	<= pressrelease; //Н
								end										

							9'h03c:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[9][3]	<= pressrelease; //U
								else
									keymatrixa[5][3]	<= pressrelease; //Г
								end																				

							9'h043:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[7][1]	<= pressrelease; //I
								else
									keymatrixa[4][3]	<= pressrelease; //Ш
								end
								
							9'h044:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[5][2]	<= pressrelease; //O
								else
									keymatrixa[3][3]	<= pressrelease; //Щ
								end
								
							9'h04d:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[7][2]	<= pressrelease; //P
								else
									keymatrixa[2][3]	<= pressrelease; //З
								end
								
							9'h054:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[4][3]	<= pressrelease; //[
								else
									keymatrixa[1][3]	<= pressrelease; //Х
								end
								
							9'h05b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[3][3]	<= pressrelease; //]
								else
									keymatrixa[0][1]	<= pressrelease; //Ъ
								end
								
							9'h01c:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[8][2]	<= pressrelease; //A
								else
									keymatrixa[11][2]	<= pressrelease; //Ф
								end
								
							9'h01b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[9][1]	<= pressrelease; //S
								else
									keymatrixa[10][2]	<= pressrelease; //Ы
								end
								
							9'h023:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[3][2]	<= pressrelease; //D
								else
									keymatrixa[9][2]	<= pressrelease; //В
								end
								
							9'h02b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[11][2]	<= pressrelease; //F
								else
									keymatrixa[8][2]	<= pressrelease; //А
								end
								
							9'h034:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[5][3]	<= pressrelease; //G
								else
									keymatrixa[7][2]	<= pressrelease; //П
								end
								
							9'h033:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[1][3]	<= pressrelease; //H
								else
									keymatrixa[6][2]	<= pressrelease; //Р
								end
																	
							9'h03b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[11][3]	<= pressrelease; //J
								else
									keymatrixa[5][2]	<= pressrelease; //О
								end
																	
							9'h042:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[8][3]	<= pressrelease; //K
								else
									keymatrixa[4][2]	<= pressrelease; //Л
								end
																	
							9'h04b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[4][2]	<= pressrelease; //L
								else
									keymatrixa[3][2]	<= pressrelease; //Д
								end
																	
							9'h04c:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[0][3]	<= pressrelease; //;
								else
									keymatrixa[2][2]	<= pressrelease; //Ж
								end
																	
							9'h052:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[3][1]	<= pressrelease; //@
								else
									keymatrixa[1][2]	<= pressrelease; //Э
								end
								
							9'h05d:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[1][2]	<= pressrelease; // '\'
								else
									keymatrixa[1][1]	<= pressrelease; // '/'
								end
								
							9'h01a:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[2][3]	<= pressrelease; //Z
								else
									keymatrixa[11][1]	<= pressrelease; //Я
								end
								
							9'h022:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[5][1]	<= pressrelease; //X
								else
									keymatrixa[10][1]	<= pressrelease; //Ч
								end
								
							9'h021:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[10][3]	<= pressrelease; //C
								else
									keymatrixa[9][1]	<= pressrelease; //С
								end
								
							9'h02a:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[2][2]	<= pressrelease; //V
								else
									keymatrixa[8][1]	<= pressrelease; //М
								end
								
							9'h032:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[4][1]	<= pressrelease; //B
								else
									keymatrixa[7][1]	<= pressrelease; //И
								end								
																							
							9'h031:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[6][3]	<= pressrelease; //N
								else
									keymatrixa[6][1]	<= pressrelease; //Т
								end
								
							9'h03a:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[8][1]	<= pressrelease; //M
								else
									keymatrixa[5][1]	<= pressrelease; //Ь
								end	
								
							9'h041:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[2][1]	<= pressrelease; //<
								else
									keymatrixa[4][1]	<= pressrelease; //Б
								end	
								
							9'h049:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[0][2]	<= pressrelease; //>
								else
									keymatrixa[3][1]	<= pressrelease; //Ю
								end	
								
							9'h04a:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[1][1]	<= pressrelease; // '/'
								else
									keymatrixa[0][2]	<= pressrelease; //.
								end
																																					
							9'h011,9'h111:begin	
									keymatrixa[11][0]	<= pressrelease; //Alt - РУС/LAT
									rl_st <= pressrelease;
									end			
												
							9'h066:	keymatrixa[0][1] 	<= pressrelease; //Забой
							9'h16c:	keymatrixa[10][0]	<= pressrelease; //Home
							9'h175:	keymatrixa[9][0]	<= pressrelease; //Up
							9'h172:	keymatrixa[8][0]	<= pressrelease; //Down
							
							9'h00d: begin
								if (mx_st_key == 1'b0) 
									keymatrixa[7][0]	<= pressrelease; //Tab
								else
									keymatrixa[3][0]	<= pressrelease; //Tab - Таб
								end

							9'h076: begin
								if (mx_st_key == 1'b0) 
									keymatrixa[6][0]	<= pressrelease; //Esc
								else
									keymatrixa[11][5]	<= pressrelease; //Esc
								end

							9'h029:	keymatrixa[5][0]	<= pressrelease; //Пробел
							9'h16b:	keymatrixa[4][0]	<= pressrelease; //Left
							9'h174:	keymatrixa[2][0]	<= pressrelease; //Right
							9'h169:	keymatrixa[1][0]	<= pressrelease; //End - ПС
							9'h05a,9'h15a: keymatrixa[0][0] <= pressrelease; //Enter
							9'h012,9'h059: shift <= pressrelease;		  //Shift - НР

						endcase
					end	
				end		
end

endmodule
