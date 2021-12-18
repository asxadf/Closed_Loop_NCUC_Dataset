%% --------------------------------Hello-------------------------------- %%
% This code details the CPO training in our paper: Feature-driven Economic
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
function[CPO_TRA_H,...
         CPO_TRA_H_ele,...
         CPO_TRA_obj,...
         CPO_TRA_cost_ERM,...
         CPO_TRA_regulation,...
         CPO_TRA_time]...
= Step_01_CPO_train(lambda,...
                    Scaler_load,...
                    Scaler_SPG,...
                    Scaler_WPG,...
                    Solver_flag, Solver_gap, Solver_time,...
                    Picked_feature,...
                    Picked_load_city,...
                    Picked_reserve_load_req,...
                    Picked_reserve_RES_req,...
                    Picked_cost_perfect,...
                    Number_picked_day_intuition,...
                    Method_flag)
%% -------------------------------Loading------------------------------- %%
clear('yalmip');
[Number_gen,...
 ~,...
 ~,...
 Number_city,...
 ~,...
 Number_hour,...
 Number_RES,...
 ~,...
 Number_point,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~] = Database_Belgium_bus24(1,...
                             1,...
                             Scaler_load,...
                             Scaler_SPG,...
                             Scaler_WPG,...
                             Method_flag);
load('UC_A_ineq');
load('UC_b_ineq');
load('UC_c');
Number_day_iteration = Number_picked_day_intuition*4;
Number_feature_all   = 22;
%% -------------------------------Decision------------------------------ %%
% UC decision
Decision_I          = binvar(Number_gen*Number_hour, Number_day_iteration);
Decision_I_SU       = binvar(Number_gen*Number_hour, Number_day_iteration);
Decision_I_SD       = binvar(Number_gen*Number_hour, Number_day_iteration);
Decision_P          = sdpvar(Number_gen*Number_hour, Number_day_iteration);
Decision_P_cost     = sdpvar(Number_gen*Number_hour, Number_day_iteration);
Decision_delta      = sdpvar(Number_gen*Number_point*Number_hour, Number_day_iteration);
Decision_R_h        = sdpvar(Number_gen*Number_hour, Number_day_iteration);
Decision_R_c        = sdpvar(Number_gen*Number_hour, Number_day_iteration);
Decision_R_all_req  = sdpvar(Number_hour, Number_day_iteration);
Decision_R_load_req = sdpvar(Number_hour, Number_day_iteration);
Decision_R_RES_req  = sdpvar(Number_hour, Number_day_iteration);
% ED decision
Decision_L_s = sdpvar(Number_city*Number_hour, Number_day_iteration);
Decision_L_r = sdpvar(Number_city*Number_hour, Number_day_iteration);
Decision_W_s = sdpvar(Number_RES*Number_hour, Number_day_iteration);
Decision_W_r = sdpvar(Number_RES*Number_hour, Number_day_iteration);
% All decision
x = [Decision_I;
     Decision_I_SU;
     Decision_I_SD;
     Decision_P;
     Decision_P_cost;
     Decision_delta;
     Decision_R_h;
     Decision_R_c;   
     Decision_R_all_req;
     Decision_R_load_req;
     Decision_R_RES_req;
     Decision_L_s;
     Decision_L_r;
     Decision_W_s;
     Decision_W_r];
% Prediction model 
H_temp = zeros(Number_RES*Number_hour, Number_feature_all*Number_hour);
Feature_selection_for_RES = [13 14 15 20 21];

for i_RES = 1:Number_RES
    Index_feature = Feature_selection_for_RES(i_RES);
    H_temp((i_RES-1)*Number_hour+1:i_RES*Number_hour,(Index_feature-1)*Number_hour+1:Index_feature*Number_hour)...
        = eye(Number_hour);
end

kk = 1;
for row = 1:size(H_temp,1)
    for column = 1:size(H_temp,2)
        if H_temp(row,column) == 1
            Counter_row(kk,1) = row;
            Counter_col(kk,1) = column;
            kk = kk + 1;
        end
    end
end
if size(Counter_row, 1) == size(Counter_col, 1)
    Number_H_element = size(Counter_row,1);
end
CPO_TRA_H = sparse(Counter_row, Counter_col, sdpvar(Number_H_element, 1));
for i_NBE = 1:Number_H_element
    CPO_TRA_H_ele(i_NBE,1) = CPO_TRA_H(Counter_row(i_NBE), Counter_col(i_NBE));
end
% Ready for traning
CPO_TRA_H = [CPO_TRA_H zeros(Number_RES*Number_hour,Number_hour)];
%% -------------------------Constraints: special------------------------ %%
CC_Special = [];
% Load realization
Load_RUM   = Picked_load_city;
CC_Special = CC_Special...
           + [Decision_L_s + Decision_L_r == Load_RUM];
% RES prediction
RES_PRE    = CPO_TRA_H*Picked_feature;
CC_Special = CC_Special...
           + [Decision_W_s + Decision_W_r == RES_PRE];
% Reserve level
Reserve_load_req = Picked_reserve_load_req;
Reserve_RES_req  = Picked_reserve_RES_req;
CC_Special  = CC_Special...
            + [Decision_R_load_req == Reserve_load_req]... 
            + [Decision_R_RES_req  == Reserve_RES_req]...   
            + [Decision_R_load_req + Decision_R_RES_req  == Decision_R_all_req];
%% -------------------------------Objective----------------------------- %%       
% Prescriptive obj and Perfect obj
Cost_prescri = (UC_c'*x)';
Cost_perfect = Picked_cost_perfect;       
% RHS vector
UC_b_ineq = repmat(UC_b_ineq, 1, Number_day_iteration);
% Cost loss
Cost_loss = (Cost_prescri - Cost_perfect);
% ERM term
CPO_TRA_cost_ERM = sum(Cost_loss)/Number_day_iteration;
% Regulation term
CPO_TRA_regulation = lambda*(norm(CPO_TRA_H,1));
% Final Obj
CPO_TRA_obj = (CPO_TRA_cost_ERM + CPO_TRA_regulation);
%% -------------------------------Constraint---------------------------- %%
Constraint = [UC_A_ineq*x <= UC_b_ineq]...
           + CC_Special ...
           + [Cost_loss >= 0];
%% --------------------------------Solve it----------------------------- %%       
if Solver_flag == 'g' 
    ops = sdpsettings('solver', 'gurobi');
    ops.gurobi.MIPGap    = Solver_gap/100;
    ops.gurobi.TimeLimit = Solver_time*60;
end
if Solver_flag == 'c'
    ops = sdpsettings('solver', 'cplex');
    ops.cplex.mip.tolerances.mipgap = Solver_gap/100; 
    ops.cplex.timelimit             = Solver_time*60;
end
if Solver_flag == 'm'
    ops = sdpsettings('solver', 'mosek');
    ops.mosek.MSK_DPAR_MIO_TOL_REL_GAP = Solver_gap/100;
    ops.mosek.MSK_DPAR_MIO_MAX_TIME    = Solver_time*60;
end
obj = optimize(Constraint, CPO_TRA_obj, ops);
CPO_TRA_time = obj.solvertime;
%% -----------------------------value it----------------------------------%
CPO_TRA_H          = value(CPO_TRA_H);
CPO_TRA_H_ele      = value(CPO_TRA_H_ele);
CPO_TRA_obj        = value(CPO_TRA_obj);
CPO_TRA_cost_ERM   = value(CPO_TRA_cost_ERM);
CPO_TRA_regulation = value(CPO_TRA_regulation);

yalmip('clear');
end