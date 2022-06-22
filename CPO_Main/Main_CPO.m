%% --------------------------------Hello-------------------------------- %%
% This code details the rolling CPO in our paper: Feature-driven Economic
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
%% Xianbang Chen, Yafei Yang, Yikui Liu, and Lei Wu. "Feature-driven Economic
% Improvement for Network-Constrained Unit Commitment: A Closed-Loop
% Predict-and-Optimize Framework," IEEE Transaction on Power Systems,
% vol. 37, no. 4, pp. 3104-3118, July 2022, doi: 10.1109/TPWRS.2021.3128485.
%% --------------------------------Hello-------------------------------- %%
%
clc;
clear;
close all;
%% 2020 Jan
Validate_day_1st = 0731;
Validate_day_end = 0760;
%% 2020 Feb
% Validate_day_1st = 0761;
% Validate_day_end = 0790;
%% 2020 Mar
% Validate_day_1st = 0791;
% Validate_day_end = 0820;
%% 2020 Apr
% Validate_day_1st = 0821;
% Validate_day_end = 0850;
%% 2020 May
% Validate_day_1st = 0851;
% Validate_day_end = 0880;
%% 2020 Jun
% Validate_day_1st = 0881;
% Validate_day_end = 0910;
%% 2020 Jul
% Validate_day_1st = 0911;
% Validate_day_end = 0940;
%% 2020 Aug
% Validate_day_1st = 0941;
% Validate_day_end = 0970;
%% 2020 Sep
% Validate_day_1st = 0971;
% Validate_day_end = 1000;
%% 2020 Oct
% Validate_day_1st = 1001;
% Validate_day_end = 1030;
%% 2020 Nov
% Validate_day_1st = 1031;
% Validate_day_end = 1060;
%% 2020 Dec
% Validate_day_1st = 1061;
% Validate_day_end = 1090;
%% 2020 Dec tail
% Validate_day_1st = 1091;
% Validate_day_end = 1096;
Number_day          = Validate_day_end - Validate_day_1st + 1;
First_day_intuition = Validate_day_1st;
Final_day_intuition = Validate_day_end;
Scaler_load         = 0.22;
Scaler_SPG          = 0.39;
Scaler_WPG          = 0.39;
R_for_load          = 0.10;
R_for_RES           = 0.05;
Method_flag         = 'CPO';
Number_hour         = 24;
Number_RES          = 5;
%% -----------------------------SPO tunning----------------------------- %%
lamda                 = 100000;
Number_training_day   = 2;
Number_day_H_validity = 7; % The frequency of updating Predictor H.
Number_historic_day   = 7;
Solver_flag           = 'g';
Solver_gap            = 3;
Solver_time           = 10;
%% -----------------------Prepare box for recorder---------------------- %%
% Rec for UC
Rec_Decision_UC_I    = cell(Number_day, 1);
Rec_Decision_UC_P    = cell(Number_day, 1);
Rec_Decision_UC_R_h  = cell(Number_day, 1);
Rec_Decision_UC_R_c  = cell(Number_day, 1);
Rec_cost_UC_expected = cell(Number_day, 1);
Rec_cost_UC_SUSD     = cell(Number_day, 1);
Rec_RES_prediction   = cell(Number_day, 1);
Rec_infea_UC_flag    = cell(Number_day, 1);
Rec_UC_time          = cell(Number_day, 1);
% Rec for ED
Rec_cost_ACT      = cell(Number_day, 1);
Rec_cost_UC       = cell(Number_day, 1);
Rec_cost_SUSD_all = cell(Number_day, 1);
Rec_cost_SUSD_UC  = cell(Number_day, 1);
Rec_cost_SUSD_ED  = cell(Number_day, 1);
Rec_cost_P        = cell(Number_day, 1);
Rec_cost_LS       = cell(Number_day, 1);
Rec_cost_loss_ACT = cell(Number_day, 1);
Rec_cost_loss_UC  = cell(Number_day, 1);
Rec_infea_ED_flag = cell(Number_day, 1);
%% --------------------------Prepare box for CPO------------------------ %%
% Cost
CPO_cost_ACT      = zeros(Number_day, 1);
CPO_cost_UC       = zeros(Number_day, 1);
CPO_cost_SUSD_all = zeros(Number_day, 1);
CPO_cost_SUSD_UC  = zeros(Number_day, 1);
CPO_cost_SUSD_ED  = zeros(Number_day, 1);
CPO_cost_P        = zeros(Number_day, 1);
CPO_cost_LS       = zeros(Number_day, 1);
CPO_cost_loss_ACT = zeros(Number_day, 1);
CPO_cost_loss_UC  = zeros(Number_day, 1);
% Flag
CPO_infeasible_UC = zeros(Number_day, 1);
CPO_infeasible_ED = zeros(Number_day, 1);
%% -------------------------Set updating frequency---------------------- %%
Number_period = ceil(Number_day/Number_day_H_validity);
if Number_period == floor(Number_day/Number_day_H_validity)
    Number_day_in_period_full           = Number_day_H_validity;
    Number_day_in_period_last           = Number_day_H_validity;
    Period_size_list                    = ones(Number_period,1);
    Period_1st_list                     = zeros(Number_period,1);
    Period_end_list                     = zeros(Number_period,1);
    Period_size_list(1:Number_period-1) = Number_day_in_period_full;
    Period_size_list(Number_period)     = Number_day_in_period_last;
end
if Number_period > floor(Number_day/Number_day_H_validity)
    Number_day_in_period_full           = Number_day_H_validity;
    Number_day_in_period_last           = Number_day - (Number_period - 1)*Number_day_H_validity;
    Period_size_list                    = ones(Number_period,1);
    Period_1st_list                     = zeros(Number_period,1);
    Period_end_list                     = zeros(Number_period,1);
    Period_size_list(1:Number_period-1) = Number_day_in_period_full;
    Period_size_list(Number_period)     = Number_day_in_period_last;
end
for i_period = 1:Number_period
    Period_1st_list(i_period) = (Validate_day_end+1) - sum(Period_size_list(i_period:end));
    Period_end_list(i_period) = (Validate_day_1st-1) + sum(Period_size_list(1:i_period));
end
%% ------------------Prepare box for training details------------------- %%
% Training detail
CPO_TRA_Predictor_H     = cell(Number_period, 1);
CPO_TRA_Predictor_H_ele = cell(Number_period, 1);
CPO_TRA_obj             = zeros(Number_period, 1);
CPO_TRA_cost_ERM        = zeros(Number_period, 1);
CPO_TRA_regulation      = zeros(Number_period, 1);
CPO_TRA_time            = zeros(Number_period, 1);
%% --------------------------Prepare box for pick----------------------- %%
Picked_TRA_intuition        = zeros(Number_training_day,Number_period);
Picked_TRA_feature          = cell(Number_period,1);
Picked_TRA_load_city        = cell(Number_period,1);
Picked_TRA_reserve_load_req = cell(Number_period,1);
Picked_TRA_reserve_RES_req  = cell(Number_period,1);
Picked_TRA_cost_perfect     = cell(Number_period,1);
%% ------------------------------Let's go------------------------------- %%
for Current_period = 1:Number_period
    Number_dispatch_day = Period_size_list(Current_period);
    Dispatch_day_1st    = Period_1st_list(Current_period);
    Dispatch_day_end    = Period_end_list(Current_period);
    %% -----------------------Select training day----------------------- %%
    [Picked_TRA_intuition(:,Current_period),...
     Picked_TRA_feature{Current_period},...
     Picked_TRA_load_city{Current_period},...
     Picked_TRA_reserve_load_req{Current_period},...
     Picked_TRA_reserve_RES_req{Current_period},...
     Picked_TRA_cost_perfect{Current_period}]...
         = Step_00_Select_train_day(Dispatch_day_1st,...
                                    Dispatch_day_end,...
                                    Number_training_day,...
                                    Number_dispatch_day,...
                                    Scaler_load,...
                                    Scaler_SPG,...
                                    Scaler_WPG,...
                                    R_for_load,...
                                    R_for_RES,...
                                    Number_historic_day);
    %% -----------------------------Setp 01----------------------------- %%
    [CPO_TRA_Predictor_H{Current_period},...
     CPO_TRA_Predictor_H_ele{Current_period},...
     CPO_TRA_obj(Current_period),...
     CPO_TRA_cost_ERM(Current_period),...
     CPO_TRA_regulation(Current_period),...
     CPO_TRA_time(Current_period)]...
     = Step_01_CPO_train(lamda,...
                         Scaler_load,...
                         Scaler_SPG,...
                         Scaler_WPG,...
                         Solver_flag, Solver_gap, Solver_time,...
                         Picked_TRA_feature{Current_period},...
                         Picked_TRA_load_city{Current_period},...
                         Picked_TRA_reserve_load_req{Current_period},...
                         Picked_TRA_reserve_RES_req{Current_period},...
                         Picked_TRA_cost_perfect{Current_period},...
                         Number_training_day,...
                         Method_flag);
for Current_day_intuition = Period_1st_list(Current_period):Period_end_list(Current_period)
    Index = Current_day_intuition - Validate_day_1st + 1;
    %% -----------------------------Setp 02----------------------------- %%
    [Rec_Decision_UC_I{Index},...
     Rec_Decision_UC_P{Index},...
     Rec_Decision_UC_R_h{Index},...
     Rec_Decision_UC_R_c{Index},...
     Rec_cost_UC_expected{Index},...
     Rec_cost_UC_SUSD{Index},...
     Rec_RES_prediction{Index},...
     Rec_infea_UC_flag{Index},...
     Rec_UC_time{Index}]...
     = Step_02_DA_UC(CPO_TRA_Predictor_H{Current_period},...
                     Current_day_intuition,...
                     Scaler_load,...
                     Scaler_SPG,...
                     Scaler_WPG,...
                     R_for_load,...
                     R_for_RES,...
                     First_day_intuition,...
                     Final_day_intuition,...
                     Method_flag);
    %% -----------------------------Setp 03----------------------------- %%
    [Rec_cost_ACT{Index},...
     Rec_cost_UC{Index},...
     Rec_cost_SUSD_all{Index},...
     Rec_cost_SUSD_UC{Index},...
     Rec_cost_SUSD_ED{Index},...
     Rec_cost_P{Index},...
     Rec_cost_LS{Index},...
     Rec_cost_loss_ACT{Index},...
     Rec_cost_loss_UC{Index},...
     Rec_infea_ED_flag{Index}]...
     = Step_03_RT_ED(Rec_Decision_UC_I{Index},...
                     Rec_Decision_UC_P{Index},...
                     Rec_Decision_UC_R_h{Index},...
                     Rec_Decision_UC_R_c{Index},...
                     Rec_cost_UC_expected{Index},...
                     Rec_cost_UC_SUSD{Index},...
                     Rec_RES_prediction{Index},...
                     Current_day_intuition,...
                     Scaler_load,...
                     Scaler_SPG,...
                     Scaler_WPG,...
                     First_day_intuition,...
                     Final_day_intuition,...
                     Method_flag);
    %% --------------------------Check infea---------------------------- %% 
    % Flag
    CPO_infeasible_UC(Index) = sum(Rec_infea_UC_flag{Index});
    CPO_infeasible_ED(Index) = sum(Rec_infea_ED_flag{Index});
    if CPO_infeasible_ED(Index) ~= 0
        for i_infea = 1:4
            if Rec_infea_ED_flag{Index}(i_infea) == 1
                Rec_cost_ACT{Index}(i_infea)      = 0.15;
                Rec_cost_SUSD_all{Index}(i_infea) = 0.15;
                Rec_cost_SUSD_ED{Index}(i_infea)  = 0.15;
                Rec_cost_P{Index}(i_infea)        = 0.15;
                Rec_cost_loss_ACT{Index}(i_infea) = 0.15;
                Rec_ED_time{Index}(i_infea)       = 0.15;  
            end
        end
        Rec_cost_ACT{Index}(Rec_cost_ACT{Index}==0.15)           = [];
        Rec_cost_SUSD_all{Index}(Rec_cost_SUSD_all{Index}==0.15) = [];
        Rec_cost_SUSD_ED{Index}(Rec_cost_SUSD_ED{Index}==0.15)   = [];
        Rec_cost_P{Index}(Rec_cost_P{Index}==0.15)               = [];
        Rec_cost_loss_ACT{Index}(Rec_cost_loss_ACT{Index}==0.15) = [];
        Rec_ED_time{Index}(Rec_ED_time{Index}==0.15)             = [];
    end
    %% ---------------------------Average it---------------------------- %%
    % Cost
    CPO_cost_ACT(Index)      = mean(Rec_cost_ACT{Index});
    CPO_cost_UC(Index)       = mean(Rec_cost_UC{Index});
    CPO_cost_SUSD_all(Index) = mean(Rec_cost_SUSD_all{Index});
    CPO_cost_SUSD_UC(Index)  = mean(Rec_cost_SUSD_UC{Index});
    CPO_cost_SUSD_ED(Index)  = mean(Rec_cost_SUSD_ED{Index});   
    CPO_cost_P(Index)        = mean(Rec_cost_P{Index});
    CPO_cost_LS(Index)       = mean(Rec_cost_LS{Index});
    CPO_cost_loss_ACT(Index) = mean(Rec_cost_loss_ACT{Index});
    CPO_cost_loss_UC(Index)  = mean(Rec_cost_loss_UC{Index});
end
end
