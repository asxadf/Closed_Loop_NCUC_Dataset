%% --------------------------------Hello-------------------------------- %%
% This code details the ED part in our paper: Feature-driven Economic
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
function[Rec_cost_ACT,...
         Rec_cost_UC,... 
         Rec_cost_SUSD_all,...
         Rec_cost_SUSD_UC,...
         Rec_cost_SUSD_ED,...
         Rec_cost_P,...
         Rec_cost_LS,...     
         Rec_cost_loss_ACT,...
         Rec_cost_loss_UC,...
         Rec_infea_ED_flag]...
= Step_03_RT_ED(Rec_Decision_UC_I,...
                Rec_Decision_UC_P,...
                Rec_Decision_UC_R_h,...
                Rec_Decision_UC_R_c,...
                Rec_cost_UC_expected,...
                Rec_cost_UC_SUSD,...
                Rec_RES_prediction,...
                Current_day_intuition,...
                Scaler_load,...
                Scaler_SPG,...
                Scaler_WPG,...
                First_day_intuition,...
                Final_day_intuition,...
                Method_flag)
%% -------------------------------Loading------------------------------- %%
Current_day_inform   = Current_day_intuition;
Remaining_day_inform = Final_day_intuition - Current_day_inform; 
First_day_iteration  = (Current_day_intuition - 1)*4 + 1;
Final_day_iteration  = Current_day_intuition*4;
[Number_gen,...
 Number_branch,...
 ~,...
 Number_city,...
 Number_day,...
 ~,...
 Number_RES,...
 ~,...
 Number_point,...
 Point_Gen,...
 Point_price,...
 Data_Gen_capacity,...
 Data_Gen_price,...
 Data_branch,...
 Data_load_country,...
 Data_load_city,...
 ~,...
 Data_RES_RUM,...
 ~,...
 PTDF_Gen,...
 PTDF_city,...
 PTDF_RES,...
 L_s_price] = Database_Belgium_bus24(First_day_iteration,...
                                      Final_day_iteration,...
                                      Scaler_load,...
                                      Scaler_SPG,...
                                      Scaler_WPG,...
                                      Method_flag);
load('Cost_perfect_ACT');
load('Cost_perfect_UC');
Number_hour    = 24;
CAP_load       = max(Data_load_country(70081:end));
CAP_RES_RES_01 = max(Data_RES_RUM.FR_SPG_RUM(70081:end));
CAP_RES_RES_02 = max(Data_RES_RUM.WR_SPG_RUM(70081:end));
CAP_RES_RES_03 = max(Data_RES_RUM.Federal_Elia_Offshore_RUM(70081:end));
CAP_RES_RES_04 = max(Data_RES_RUM.FR_WPG_RUM(70081:end));
CAP_RES_RES_05 = max(Data_RES_RUM.WR_WPG_RUM(70081:end));
CAP_RES_one    = max([CAP_RES_RES_01...
                      CAP_RES_RES_02...
                      CAP_RES_RES_03...
                      CAP_RES_RES_04...
                      CAP_RES_RES_05]);
CAP_RES_SUM  = CAP_load;
%% ------------------------------Output box----------------------------- %%
% Prepare output box of cost
Rec_cost_ACT      = zeros(Number_day, 1);
Rec_cost_UC       = Rec_cost_UC_expected;
Rec_cost_SUSD_all = zeros(Number_day, 1);
Rec_cost_SUSD_UC  = Rec_cost_UC_SUSD;
Rec_cost_SUSD_ED  = zeros(Number_day, 1);
Rec_cost_P        = zeros(Number_day, 1);
Rec_cost_LS       = zeros(Number_day, 1);
Rec_cost_loss_ACT = zeros(Number_day, 1);
Rec_cost_loss_UC  = zeros(Number_day, 1);
% Prepare output box of prediction error
Rec_PE_MAE    = zeros(Number_day, 1);
Rec_PE_MAPE   = zeros(Number_day, 1);
Rec_PE_RMSE   = zeros(Number_day, 1);
Rec_PE_R2     = zeros(Number_day, 1);
Rec_PE_WaDis  = zeros(Number_day, 1);
Rec_PE_Eover  = zeros(Number_day, 1);
Rec_PE_Eunder = zeros(Number_day, 1);
Rec_PE_Egap   = zeros(Number_day, 1);
% Prepare output box of rate
Rec_rate_RES      = zeros(Number_day, 1);
Rec_rate_LS       = zeros(Number_day, 1);
Rec_rate_Rh_act   = cell(Number_day, 1);
Rec_rate_Rh_24h   = zeros(Number_day, Number_hour);
Rec_rate_Rc_act   = cell(Number_day, 1);
Rec_rate_Rc_24h   = zeros(Number_day, Number_hour);
Rec_rate_line_act = cell(Number_day, 1);
Rec_rate_line_max = zeros(Number_hour, Number_day);
Rec_rate_line_avr = zeros(Number_hour, Number_day);
% Prepare output box of SUSD
Rec_I_UC = Rec_Decision_UC_I;
Rec_I_ED = cell(Number_day, 1);
% Prepare output box of daily curve
Rec_curve_load_daily        = cell(Number_day, 1);
Rec_curve_RES_one_PRE_daily = cell(Number_day, 1);
Rec_curve_RES_one_RUM_daily = cell(Number_day, 1);
Rec_curve_RES_SUM_PRE_daily = cell(Number_day, 1);
Rec_curve_RES_SUM_RUM_daily = cell(Number_day, 1);
% Infeasible flag
Rec_infea_ED_flag = zeros(Number_day, 1);
% Solving time
Rec_ED_time = zeros(Number_day, 1);
%% -------------------------------Let's go------------------------------ %%
Version = 1;
for Day_iteration = First_day_iteration:Final_day_iteration
    clear('yalmip');
    Index = Day_iteration - First_day_iteration + 1;
    Cost_FIM_ACT = Cost_perfect_ACT(Day_iteration);
    Cost_FIM_UC  = Cost_perfect_UC(Day_iteration);
    %% -----------------------------Decision---------------------------- %%
    % Decision for UC
    Decision_UC_I   = Rec_Decision_UC_I{Index};
    Decision_UC_P   = Rec_Decision_UC_P{Index};
    Decision_UC_R_h = Rec_Decision_UC_R_h{Index};
    Decision_UC_R_c = Rec_Decision_UC_R_c{Index};
    % Decision for ED
    Decision_ED_I        = binvar(Number_gen, Number_hour);
    Decision_ED_I_c_to_h = binvar(Number_gen, Number_hour);
    Decision_ED_P        = sdpvar(Number_gen, Number_hour);
    Decision_ED_P_up     = sdpvar(Number_gen, Number_hour);
    Decision_ED_P_up_I   = binvar(Number_gen, Number_hour);
    Decision_ED_P_dn     = sdpvar(Number_gen, Number_hour);
    Decision_ED_P_dn_I   = binvar(Number_gen, Number_hour);
    Decision_ED_P_cost   = sdpvar(Number_gen, Number_hour);
    Decision_ED_delta    = sdpvar(Number_gen*Number_point, Number_hour);
    Decision_ED_L_s      = sdpvar(Number_hour, Number_city);
    Decision_ED_L_r      = sdpvar(Number_hour, Number_city);
    Decision_ED_W_s      = sdpvar(Number_hour, Number_RES);
    Decision_ED_W_r      = sdpvar(Number_hour, Number_RES);
    %% -----------------------Constraints: general---------------------- %%
    CC_General = [];
    % Non-negative
    CC_General = CC_General ...
               + [Decision_ED_L_s == 0]...
               + [Decision_ED_L_r >= 0]...
               + [Decision_ED_W_s >= 0]...
               + [Decision_ED_W_r >= 0];
    % Delta
    CC_General = CC_General + [0 <= Decision_ED_delta <= 1];
    for t = 1:Number_hour
        % Power Balance
        CC_General = CC_General...
                   + [sum(Decision_ED_P(:,t)) + sum(Decision_ED_W_r(t,:)) == sum(Decision_ED_L_r(t,:))];
        % Line capacity
        CC_General = CC_General ...
                   + [ - Data_branch(:,4) ... 
                      <= PTDF_Gen*Decision_ED_P(:,t) ...
                       + PTDF_RES*Decision_ED_W_r(t,:)' ...
                       - PTDF_city*Decision_ED_L_r(t,:)' ...
                      <= Data_branch(:,4)];
        % Ramping capacity          
        if (t >= 2)
            CC_General = CC_General...
                       + [   Decision_ED_P(:,t) - Decision_ED_P(:,t-1)...
                          <= Data_Gen_capacity(:,7).*Decision_ED_I(:,t-1)...
                           + Data_Gen_capacity(:,9).*(Decision_ED_I(:,t) - Decision_ED_I(:,t-1))...
                           + Data_Gen_capacity(:,4).*(1 - Decision_ED_I(:,t))];
            CC_General = CC_General...
                       + [   Decision_ED_P(:,t-1) - Decision_ED_P(:,t)...
                          <= Data_Gen_capacity(:,8).*Decision_ED_I(:,t)...
                           + Data_Gen_capacity(:,10).*(Decision_ED_I(:,t-1) - Decision_ED_I(:,t))...
                           + Data_Gen_capacity(:,4).*(1 - Decision_ED_I(:,t-1))];                
        end
    end
    %% -------------------------Constraints: ED------------------------- %%
    CC_hot  = [];
    CC_cold = [];
    CC_unav = [];
    for i = 1:Number_gen
        for t = 1:Number_hour
            %% -------------------Constraints for hot------------------- %%
            if (Decision_UC_I(i,t) == 1)
                % Hold the commitment decision
                CC_hot = CC_hot + [ Decision_ED_I(i,t) == Decision_UC_I(i,t)];
                % Close the cold-to-hot decision
                CC_hot = CC_hot + [ Decision_ED_I_c_to_h(i,t) == 0];
                % Generation after adjustment
                CC_hot = CC_hot...
                       + [Decision_ED_P(i,t) == Decision_UC_P(i,t)...
                                              + Decision_ED_P_up(i,t)...
                                              - Decision_ED_P_dn(i,t)]; 
                % Adjustment limitation
                CC_hot = CC_hot...
                       + [0 <= Decision_ED_P_up(i,t) <= Decision_ED_P_up_I(i,t)*Decision_UC_R_h(i,t)]...
                       + [0 <= Decision_ED_P_dn(i,t) <= Decision_ED_P_dn_I(i,t)*Decision_UC_R_h(i,t)]...
                       + [Decision_ED_P_up_I(i,t) + Decision_ED_P_dn_I(i,t) <= 1];                                                               
                % Generation limitation
                CC_hot = CC_hot...
                       + [   Decision_ED_I(i,t)*Data_Gen_capacity(i,3)...
                          <= Decision_ED_P(i,t) <= ...
                             Decision_ED_I(i,t)*Data_Gen_capacity(i,4)];
                % Locally idea formulation: Generation cost
                CC_hot = CC_hot...
                       + [   Decision_ED_P_cost(i,t)...
                          == Point_price(i,:)...
                             *Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t)];
                % Locally idea formulation: Commitment decision
                CC_hot = CC_hot...        
                       + [   Decision_ED_I(i,t)...
                          == sum(Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t))];
                % Locally idea formulation: Generation decision
                CC_hot = CC_hot...
                       + [   Decision_ED_P(i,t)...
                          == Point_Gen(i,:)*Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t)]; 
            end
            %% ------------------Constraints for cold------------------- %%       
            if (Decision_UC_I(i,t) == 0) && (Decision_UC_R_c(i,t) ~= 0)
                % Open the cold-to-hot decision
                CC_cold = CC_cold + [ Decision_ED_I_c_to_h(i,t) == Decision_ED_I(i,t)];
                % Adjustment limitation
                CC_cold = CC_cold...
                        + [Decision_ED_P_up(i,t) == 0]   + [Decision_ED_P_dn(i,t) == 0]...
                        + [Decision_ED_P_up_I(i,t) == 0] + [Decision_ED_P_dn_I(i,t) == 0];
                % Generation limitation
                CC_cold = CC_cold...
                        + [   Decision_ED_I_c_to_h(i,t)*Data_Gen_capacity(i,3)...
                           <= Decision_ED_P(i,t) <= ...
                              Decision_ED_I_c_to_h(i,t)*Decision_UC_R_c(i,t)];
                % Locally idea formulation: Generation cost
                CC_cold = CC_cold...
                        + [   Decision_ED_P_cost(i,t)...
                           == Point_price(i,:)...
                              *Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t)];
                % Locally idea formulation: Commitment decision
                CC_cold = CC_cold...        
                        + [   Decision_ED_I(i,t)...
                           == sum(Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t))];
                % Locally idea formulation: Generation decision
                CC_cold = CC_cold...
                        + [   Decision_ED_P(i,t)...
                           == Point_Gen(i,:)*Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t)];
            end
            %% ---------------Constraints for unavailable--------------- %%         
            if (Decision_UC_I(i,t) == 0) && (Decision_UC_R_c(i,t) == 0)
                % Hold the commitment decision
                CC_unav = CC_unav + [ Decision_ED_I(i,t) == Decision_UC_I(i,t)];
                % Adjustment limitation
                CC_unav = CC_unav...
                        + [Decision_ED_P_up(i,t) == 0]   + [Decision_ED_P_dn(i,t) == 0]...
                        + [Decision_ED_P_up_I(i,t) == 0] + [Decision_ED_P_dn_I(i,t) == 0];
                % Close the cold-to-hot decision
                CC_unav = CC_unav + [ Decision_ED_I_c_to_h(i,t) == Decision_ED_I(i,t)];
                % Close generation
                CC_unav = CC_unav + [ Decision_ED_P(i,t) == 0];
                % Locally idea formulation: Generation cost
                CC_unav = CC_unav...
                        + [   Decision_ED_P_cost(i,t)...
                           == Point_price(i,:)...
                              *Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t)];
                % Locally idea formulation: Commitment decision
                CC_unav = CC_unav...
                        + [   Decision_ED_I(i,t)...
                           == sum(Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t))];
                % Locally idea formulation: Generation decision
                CC_unav = CC_unav...
                        + [   Decision_ED_P(i,t)...
                           == Point_Gen(i,:)*Decision_ED_delta((i-1)*Number_point+1:i*Number_point,t)];
            end
        end
    end
    %% -----------------------Constraints: special---------------------- %%
    CC_Special = [];
    % CC_Special_01: Load shedding limit
    Load_RUM   = Data_load_city{Number_hour*(Day_iteration-1)+1:Number_hour*Day_iteration, :};
    CC_Special = CC_Special + [Decision_ED_L_s(:) + Decision_ED_L_r(:) == Load_RUM(:)];
    % CC_Special_02: RES curtailment limit
    RES_RUM    = Data_RES_RUM{(Number_hour*(Day_iteration-1)+1:Number_hour*Day_iteration), :};
    CC_Special = CC_Special + [Decision_ED_W_s(:) + Decision_ED_W_r(:) == RES_RUM(:)];
    %
    %% -------------------------Constraints: all------------------------ %%
    CC = CC_General + CC_hot + CC_cold + CC_unav + CC_Special;
    %
    %% ----------------------------Objective---------------------------- %%
    Cost_ED_SUSD = Data_Gen_price(:,5)'*sum(Decision_ED_I_c_to_h, 2);
    Cost_ED_P    = sum(Decision_ED_P_cost(:));
    Cost_ED_LS   = L_s_price*sum(Decision_ED_L_s(:));
    Cost_ED      = Cost_ED_SUSD + Cost_ED_P + Cost_ED_LS;
    %
    %% -----------------------------Solve it---------------------------- %%
    ops = sdpsettings('solver', 'gurobi');
    tic;
    t1 = clock;
    optimize(CC, Cost_ED, ops);
    t2 = clock;
    toc;
    %% --------------------------Value decision------------------------- %%
    Decision_ED_L_s      = value(Decision_ED_L_s);
    Decision_ED_L_r      = value(Decision_ED_L_r);
    Decision_ED_W_r      = value(Decision_ED_W_r);
    Decision_ED_I_c_to_h = round(value(Decision_ED_I_c_to_h));
    Decision_ED_P        = value(Decision_ED_P);
    % Prediction
    RES_PRE = zeros(Number_hour,Number_RES);
    for i_RES = 1:Number_RES
        RES_PRE(:,i_RES) = Rec_RES_prediction((i_RES-1)*Number_hour+1:i_RES*Number_hour,Index);
    end
    %% ----------------------------Value cost--------------------------- %%
    Cost_ED_SUSD = value(Cost_ED_SUSD);
    Cost_ED_P    = value(Cost_ED_P);
    Cost_ED_LS   = value(Cost_ED_LS);
    Cost_ED      = value(Cost_ED);
    %% ---------------------------Record cost--------------------------- %%    
    Rec_cost_ACT(Index)      = Rec_cost_UC_SUSD(Index) + Cost_ED;
    Rec_cost_SUSD_all(Index) = Rec_cost_UC_SUSD(Index) + Cost_ED_SUSD;
    Rec_cost_SUSD_ED(Index)  = Cost_ED_SUSD;
    Rec_cost_P(Index)        = Cost_ED_P;
    Rec_cost_LS(Index)       = Cost_ED_LS;
    Rec_cost_loss_ACT(Index) = 100*(Rec_cost_ACT(Index) - Cost_FIM_ACT)/Cost_FIM_ACT;
    Rec_cost_loss_UC(Index)  = 100*(Rec_cost_UC(Index) - Cost_FIM_UC)/Cost_FIM_UC;
    %
    %% ----------------------------Check ED----------------------------- %%
    if isnan(Cost_ED) ||  Cost_ED == 0
        Rec_infea_ED_flag(Index) = 1;
    end
    %% --------------------------Solving time--------------------------- %%   
    Rec_ED_time(Index) = etime(t2,t1);
    %% ----------------------------Display it--------------------------- %%  
    Infom_01 = ['First     day ===> ', num2str(First_day_intuition)];
    Infom_02 = ['Final     day ===> ', num2str(Final_day_intuition)];
    Infom_03 = ['Current   day ===> ', num2str(Current_day_inform), ' .V', num2str(Version)];
    Infom_04 = ['Remaining day ===> ', num2str(Remaining_day_inform)];
    disp('%%%%%%%%%%%%%%%%%%%%%%% ED MODE %%%%%%%%%%%%%%%%%%%%%%%');
    disp(Infom_01);
    disp(Infom_02);
    disp(Infom_03);
    disp(Infom_04);
    disp('%%%%%%%%%%%%%%%%%%%%%%% ED MODE %%%%%%%%%%%%%%%%%%%%%%%');
    Version = Version + 1;
    if Version > 4 
        Version = 1;
    end
    yalmip('clear');
end
end