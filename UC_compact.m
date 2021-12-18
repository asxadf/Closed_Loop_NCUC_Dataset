%% --------------------------------Hello-------------------------------- %%
% This code details the UC model in our paper: Feature-driven Economic
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
clc;
clear;
close all;
%% -------------------------------Setting------------------------------- %%
Dispatch_day = 1;
Day_1st      = Dispatch_day;
Day_end      = Dispatch_day;
Scaler_load  = 0.22;
Scaler_SPG   = 0.39;
Scaler_WPG   = 0.39;
R_for_load   = 0.10;
R_for_RES    = 0.05;
R_h_level    = 0.20;
Method_flag  = 'OPO';
%% -------------------------------Loading------------------------------- %%
[Number_gen,...
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
                                         Method_flag);
load('UC_A_ineq');
load('UC_b_ineq');
load('UC_c');
%% -------------------------------Decision------------------------------ %%
% UC decision
Decision_I          = binvar(Number_gen, Number_hour);
Decision_I_SU       = binvar(Number_gen, Number_hour);
Decision_I_SD       = binvar(Number_gen, Number_hour);
Decision_P          = sdpvar(Number_gen, Number_hour);
Decision_P_cost     = sdpvar(Number_gen, Number_hour);
Decision_delta      = sdpvar(Number_gen*Number_point, Number_hour);
Decision_R_h        = sdpvar(Number_gen, Number_hour);
Decision_R_c        = sdpvar(Number_gen, Number_hour);
Decision_R_all_req  = sdpvar(Number_hour, 1);
Decision_R_load_req = sdpvar(Number_hour, 1);
Decision_R_RES_req  = sdpvar(Number_hour, 1);
% ED decision
Decision_L_s = sdpvar(Number_hour, Number_city);
Decision_L_r = sdpvar(Number_hour, Number_city);
Decision_W_s = sdpvar(Number_hour, Number_RES);
Decision_W_r = sdpvar(Number_hour, Number_RES);
% All decision
x = [Decision_I(:);
     Decision_I_SU(:);
     Decision_I_SD(:);
     Decision_P(:);
     Decision_P_cost(:);
     Decision_delta(:);
     Decision_R_h(:);
     Decision_R_c(:);
     Decision_R_all_req(:);
     Decision_R_load_req(:);
     Decision_R_RES_req(:);
     Decision_L_s(:);
     Decision_L_r(:);
     Decision_W_s(:);
     Decision_W_r(:)];
%% -------------------------Constraints: general------------------------ %%
CC_General = [UC_A_ineq*x <= UC_b_ineq];
%
%% -------------------------Constraints: special------------------------ %%
CC_Special = [];
% CC_Special_01: Load shedding limit
Load_RUM      = Data_load_city{24*(Day_1st-1)+1:24*Day_end, :};
Country_Load  = sum(Load_RUM,2);
CC_Special    = CC_Special + [Decision_L_s(:) + Decision_L_r(:) == Load_RUM(:)];
% CC_Special_02: RES curtailment limit
RES_DAF     = Data_RES_DAF{(24*(Day_1st-1)+1:24*Day_end), :};
Country_RES = sum(RES_DAF,2);
CC_Special  = CC_Special + [Decision_W_s(:) + Decision_W_r(:) == RES_DAF(:)];
% CC_Special_03: Provided reseve
CC_Special = CC_Special...
           + [Decision_R_load_req == R_for_load*Country_Load]...
           + [Decision_R_RES_req  == R_for_RES*Country_RES]...
           + [Decision_R_load_req + Decision_R_RES_req == Decision_R_all_req];
%
%% ---------------------------Constraints: all-------------------------- %%
CC = CC_General + CC_Special;
%
%% ------------------------------Objective------------------------------ %%
Cost_UC = UC_c'*x;
%% -------------------------------Solve it------------------------------ %%
ops = sdpsettings('solver', 'gurobi');
obj = optimize(CC, Cost_UC, ops);
UC_TIME = obj.solvertime;
%% -------------------------------Value it------------------------------ %%
Decision_I          = round(value(Decision_I));
Decision_I_SU       = round(value(Decision_I_SU));
Decision_I_SD       = round(value(Decision_I_SD));
Decision_R_h        = round(value(Decision_R_h));
Decision_R_c        = round(value(Decision_R_c));
Decision_R_all_req  = value(Decision_R_all_req);
Decision_R_load_req = value(Decision_R_load_req);
Decision_R_RES_req  = value(Decision_R_RES_req);

Decision_P      = round(value(Decision_P),5);
Decision_P_cost = value(Decision_P_cost);
Decision_delta  = value(Decision_delta);
Decision_L_s    = value(Decision_L_s);
Decision_L_r    = value(Decision_L_r);
Decision_W_s    = value(Decision_W_s);
Decision_W_r    = value(Decision_W_r);

Cost_SU  = Data_Gen_price(:,5)'*sum(Decision_I_SU,2);
Cost_SD  = Data_Gen_price(:,6)'*sum(Decision_I_SD,2);
Cost_P   = sum(Decision_P_cost(:));
Cost_L_s = sum(L_s_price*Decision_L_s(:));
Cost_UC  = Cost_SU + Cost_SD + Cost_P + Cost_L_s;