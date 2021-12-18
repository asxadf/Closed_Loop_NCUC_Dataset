%% --------------------------------Hello-------------------------------- %%
% This code details the Database in our paper: Feature-driven Economic
% Improvement for Network-Constrained Unit Commitment: A Closed-Loop
% Predict-and-Optimize Framework.
%
% Please let me know if you have concerns about this code.
% It is my pleasure to discuss/explain with you.
%
% My academic email: xchen130@stevens.edu
% My personal email: chenxianbang@hotmail.com
%
% Please cite our paper if you use this code in your research:
%
% Xianbang Chen, Yafei Yang, Yikui Liu, and Lei Wu. "Feature-driven Economic
% Improvement for Network-Constrained Unit Commitment: A Closed-Loop
% Predict-and-Optimize Framework," IEEE Transaction on Power Systems, 2021.
%% --------------------------------Hello-------------------------------- %%
%
%% ------------------------RES plant information------------------------ %%
% RES #01  FR_SPG               bus #18  [0, 2800]  AVR: 318
% RES #02  WR_SPG               bus #15  [0, 0783]  AVR: 110
% RES #03  OF_WPG               bus #01  [0, 2144]  AVR: 560
% RES #04  FR_WPG               bus #21  [0, 0995]  AVR: 220
% RES #05  WR_WPG               bus #10  [0, 0800]  AVR: 177
%                                        [0, 7522]  AVR: 1385
% FR: Flemish region 
% WR: Walloon region
% OF: Offshore region
%% --------------------------City information--------------------------- %%
% City number and name          Bus #   Load proportion
% City #01: BR_Brussels         bus #14 06.8%
% City #02: FR_Antwerp          bus #13 09.3%
% City #03: FR_Brabant_Flemish  bus #19 06.4%
% City #04: FR_Flanders_East    bus #18 11.7%
% City #05: FR_Flanders_West    bus #16 03.5%
% City #06: FR_Limburg          bus #20 04.5%
% City #07: WR_Brabant_Wallon   bus #05 02.5%
% City #08: WR_Hainaut          bus #02 03.4%
% City #09: WR_Liege            bus #06 04.8%
% City #10: WR_Luxembourg       bus #07 04.4%
% City #11: WR_Namur            bus #08 06.0%
% City #12: WR_City_01          bus #01 03.8%
% City #13: WR_City_02          bus #03 06.3%
% City #14: WR_City_03          bus #04 02.6%
% City #15: WR_City_04          bus #09 06.1%
% City #16: WR_City_05          bus #10 06.8%
% City #17: WR_City_06          bus #15 11.1%
%
%% --------------------------Data_Gen_capacity-------------------------- %%
%  Column  #1           #2            #3          #4          #5        
%  Type    Number       Location_bus  Min_output  Max_output  Minimal_on
%  Column  #6           #7            #8          #9          #10
%  Type    Minimal_off  Ramp_up       Ramp_down   SU_rampup   SD_rampdown  
%  Column  #11          #12       
%  Type    Res_hot_max  Res_cool_max
%
%% ----------------------------Data_Gen_price--------------------------- %%
%  Column  #1      #2  #3  #4  #5        #6        
%  Type    Number  c0  c1  c2  SU_price  SD_price
%
%% ------------------------------Data_Branch---------------------------- %%
%  Column  #1      #2    #3    #4          
%  Type    Number  fbus  tbus  Capacity
%
%% --------------------------Data_load_country-------------------------- %%
%  Column  #1    #2           #3           #4      
%  Type    Date  Hour_of_day  Min_of_hour  RUM
%
%% ---------------------------Data_load_city---------------------------- %%
%  Column  #1    #2           #3           #4          ... #14
%  Type    Date  Hour_of_day  Min_of_hour  City_01_RUM ... City_17_RUM
%
%% ----------------------------Data_RES_DAF----------------------------- %%
%  Column  #1    #2           #3           #4             #8
%  Type    Date  Hour_of_day  Min_of_hour  RES_01_DAF ... RES_05_DAF
%
%% ----------------------------Data_RES_RUM----------------------------- %%
%  Column  #1    #2           #3           #4              #8
%  Type    Date  Hour_of_day  Min_of_hour  RES_01_RUM ... RES_05_RUM
%
%% ----------------------------Data_feature----------------------------- %%
%  Row 001:024  Type #01 Hour_of_day 
%  Row 025:048  Type #02 BR_Brussels_DAF
%  Row 049:072  Type #03 FR_Antwerp_DAF
%  Row 073:096  Type #04 FR_Brabant_Flemish_DAF
%  Row 097:120  Type #05 FR_Flanders_East_DAF
%  Row 121:144  Type #06 FR_Flanders_West_DAF
%  Row 145:168  Type #07 FR_Limburg_DAF
%  Row 169:192  Type #08 WR_Brabant_Wallon_DAF
%  Row 193:216  Type #09 WR_Hainaut_DAF
%  Row 217:240  Type #10 WR_Liege_DAF
%  Row 241:264  Type #11 WR_Luxembourg_DAF
%  Row 265:288  Type #12 WR_Namur_DAF
%  Row 289:312  Type #13 FR_SPG_DAF
%  Row 313:336  Type #14 WR_SPG_DAF
%  Row 337:360  Type #15 Federal_Elia_Offshore_DAF
%  Row 361:384  Type #16 FR_DSO_Onshore_DAF
%  Row 385:408  Type #17 FR_Elia_Onshore_DAF
%  Row 409:432  Type #18 WR_DSO_Onshore_DAF
%  Row 433:456  Type #19 WR_Elia_Onshore_DAF
%  Row 457:480  Type #20 FR_WPG_DAF
%  Row 481:504  Type #21 WR_WPG_DAF
%  Row 505:528  Type #22 Load_country
%% ----------------------------Start function--------------------------- %%
function[Number_gen,...
         Number_branch,...
         Number_bus,...
         Number_city,...
         Number_day,...
         Number_hour,...
         Number_RES,...
         Number_seg,...
         Number_point,...
         Point_Gen,...
         Point_price,...
         Data_Gen_capacity,...
         Data_Gen_price,...
         Data_branch,...
         Data_load_country,...
         Data_load_city,...
         Data_RES_DAF,...
         Data_RES_RUM,...
         Data_feature,...
         PTDF_Gen,...
         PTDF_city,...
         PTDF_RES,...
         L_s_price] = CPO_Database_Belgium_bus24(Day_1st,...
                                                 Day_end,...
                                                 Scaler_load,...
                                                 Scaler_SPG,...
                                                 Scaler_WPG,...
                                                 Method_flag)
%% -------------------------------Loading------------------------------- %%
mpc  = CPO_Data_case24_ieee_rts;
PTDF = round(makePTDF(mpc), 4);
load('CPO_Data_load_country');     % Total load of system
load('CPO_Data_SPG_DAF');          % Day-ahead Forecasting 
load('CPO_Data_WPG_DAF');          % Day-ahead Forecasting 
load('CPO_Data_SPG_RUM');          % Real-time Measurement 
load('CPO_Data_WPG_RUM');          % Real-time Measurement 
load('CPO_Data_branch');
load('CPO_Data_Gen_capacity');
load('CPO_Data_Gen_price');
%% -----------------------------Basic Data------------------------------ %%
% Number of element
Number_gen    = 32;
Number_branch = 38;
Number_bus    = 24;
Number_city   = 17;
Number_day    = Day_end - Day_1st + 1;
Number_hour   = 24*Number_day;
Number_RES    = 5;
Number_seg    = 2;
Number_point  = Number_seg + 1;
% City bus
City_bus    = [   14;    13;    19;    18;    16;    20;... FR
                  05;    02;    06;    07;    08;...        WR
                  01;    03;    04;    09;    10;    15];                     
City_weight = [0.068; 0.093; 0.064; 0.117; 0.035; 0.045;...
               0.025; 0.034; 0.048; 0.044; 0.060; 0.038;...
               0.063; 0.026; 0.061; 0.068; 0.111];          
% Penalty price
L_s_price  = 2000;
% RES bus
FR_SPG_bus = 18;
WR_SPG_bus = 15;
OF_WPG_bus = 1;
FR_WPG_bus = 21;
WR_WPG_bus = 10;
RES_bus = [FR_SPG_bus; WR_SPG_bus; OF_WPG_bus; FR_WPG_bus; WR_WPG_bus];
%% ---------------------------Data_Gen_price---------------------------- %%
% Get quadratic function of gen cost
% Cut generation range
Generation_sub_range =...
(Data_Gen_capacity(:,4) - Data_Gen_capacity(:,3))/Number_seg;
% Get 1st point of gernation
Point_Gen = Data_Gen_capacity(:,3);
% Get 1st point of price
Point_price = Data_Gen_price(:,2)...
            + Data_Gen_price(:,3).*Data_Gen_capacity(:,3)...
            + Data_Gen_price(:,4).*Data_Gen_capacity(:,3).^2;
for i = 1:Number_gen    
    for k = 1:Number_seg
        % Get 2nd to end point of generation
          Point_Gen(i,k+1)...
        = Data_Gen_capacity(i,3)...
        + k*Generation_sub_range(i,1);
        % Get 2nd to end point of price
          Point_price(i,k+1)...
        = Data_Gen_price(i,2)...
        + Data_Gen_price(i,3)*Point_Gen(i,k+1)...
        + Data_Gen_price(i,4)*Point_Gen(i,k+1)^2;
    end
end
%
%% --------------------------Data_Load_country-------------------------- %%
Data_load_country = Scaler_load*Data_load_country;
%
%% ---------------------------Data_Load_city---------------------------- %%
Load_Brussels        = Data_load_country*City_weight(01);
Load_Antwerp         = Data_load_country*City_weight(02);
Load_Brabant_Flemish = Data_load_country*City_weight(03);
Load_Flanders_East   = Data_load_country*City_weight(04);
Load_Flanders_West   = Data_load_country*City_weight(05);
Load_Limburg         = Data_load_country*City_weight(06);
Load_Brabant_Wallon  = Data_load_country*City_weight(07);
Load_Hainaut         = Data_load_country*City_weight(08);
Load_Liege           = Data_load_country*City_weight(09);
Load_Luxemburg       = Data_load_country*City_weight(10);
Load_Namur           = Data_load_country*City_weight(11);
Load_WR_city_01      = Data_load_country*City_weight(12);
Load_WR_city_02      = Data_load_country*City_weight(13);
Load_WR_city_03      = Data_load_country*City_weight(14);
Load_WR_city_04      = Data_load_country*City_weight(15);
Load_WR_city_05      = Data_load_country*City_weight(16);
Load_WR_city_06      = Data_load_country*City_weight(17);
Data_load_city = table(Load_Brussels,...
                       Load_Antwerp,...
                       Load_Brabant_Flemish,...
                       Load_Flanders_East,...
                       Load_Flanders_West,...
                       Load_Limburg,...
                       Load_Brabant_Wallon,...
                       Load_Hainaut,...
                       Load_Liege,...
                       Load_Luxemburg,...
                       Load_Namur,...
                       Load_WR_city_01,...
                       Load_WR_city_02,...
                       Load_WR_city_03,...
                       Load_WR_city_04,...
                       Load_WR_city_05,...
                       Load_WR_city_06);
%
%% -----------------------------Data_feature---------------------------- %%
if Method_flag == 'CPO'
    load('CPO_Data_feature_CPO');
    Data_feature             = Data_feature_CPO;
    Data_feature(025:336, :) = Scaler_SPG*Data_feature(025:336, :);
    Data_feature(337:504, :) = Scaler_WPG*Data_feature(337:504, :);
    Data_feature(505:528, :) = Scaler_load*Data_feature(505:528, :);
end
if Method_flag == 'OPO'
    load('CPO_Data_feature_OPO');
    Data_feature             = Data_feature_OPO;
    Data_feature(025:336, :) = Scaler_SPG*Data_feature(025:336, :);
    Data_feature(337:504, :) = Scaler_WPG*Data_feature(337:504, :);
    Data_feature(505:528, :) = Scaler_load*Data_feature(505:528, :);
end
if Method_flag == 'PPO'
    load('CPO_Data_feature_PPO');
    Data_feature             = Data_feature_PPO;
    Data_feature(025:336, :) = Scaler_SPG*Data_feature(025:336, :);
    Data_feature(337:504, :) = Scaler_WPG*Data_feature(337:504, :);
    Data_feature(505:528, :) = Scaler_load*Data_feature(505:528, :);
end
%% -----------------------------Data_RES_DAF---------------------------- %%
SPG_DAF{:, 4:16} = Scaler_SPG*SPG_DAF{:, 4:16};
WPG_DAF{:, 4:10} = Scaler_WPG*WPG_DAF{:, 4:10};
Data_RES_DAF     = [SPG_DAF(:, 15:16) WPG_DAF(:, 4) WPG_DAF(:, 9:10)];
%
%% -----------------------------Data_RES_RUM---------------------------- %%
SPG_RUM{:, 4:16} = Scaler_SPG*SPG_RUM{:, 4:16};
WPG_RUM{:, 4:10} = Scaler_WPG*WPG_RUM{:, 4:10};
Data_RES_RUM     = [SPG_RUM(:, 15:16) WPG_RUM(:, 4) WPG_RUM(:, 9:10)];
%
%% -------------------------------PTDF_Gen------------------------------ %%
for i = 1:Number_gen
    PTDF_Gen(:,i) = PTDF(:, Data_Gen_capacity(i, 2));
end
%
%% -------------------------------PTDF_load----------------------------- %%
for i = 1:Number_city
    PTDF_city(:,i) = PTDF(:, City_bus(i, 1));
end
%
%% -------------------------------PTDF_RES------------------------------ %%
for i = 1:Number_RES
    PTDF_RES(:,i) = PTDF(:, RES_bus(i, 1));
end
end