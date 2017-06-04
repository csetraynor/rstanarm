    # !!! Be careful that indexing of has_assoc matches stan_jm file
   
    for (m in 1:M) {

      //----- etavalue or etaslope, and any interactions     

      if (has_assoc[1,m]  == 1 || // etavalue
          has_assoc[9,m]  == 1 || // etavalue * data
          has_assoc[13,m] == 1 || // etavalue * etavalue
          has_assoc[14,m] == 1 || // etavalue * muvalue 
          has_assoc[2,m]  == 1 || // etaslope
          has_assoc[10,m] == 1) { // etaslope * data
          
        // declare and define eta for submodel m  
        vector[nrow_y_Xq[m]] eta_tmp; 
        eta_tmp = y_eta_q[idx_q[m,1]:idx_q[m,2]];

        // add etavalue and any interactions to event submodel eta
        mark2 = mark2 + 1; // count even if assoc type isn't used
        if (has_assoc[1,m] == 1) { # etavalue
          vector[nrow_e_Xq] val;    
          if (has_clust[m] == 1) 
            val = clust_mat[, idx_clust[m,1]:idx_clust[m,2]] * eta_tmp;
          else val = eta_tmp;
          mark = mark + 1;
  	      e_eta_q = e_eta_q + a_beta[mark] * val;
        }	
        if (has_assoc[9,m] == 1) { # etavalue*data
    	    int tmp = a_K_data[mark2];
    	    int j_shift = (mark2 == 1) ? 0 : sum(a_K_data[1:(mark2-1)]);
          for (j in 1:tmp) {
            vector[nrow_e_Xq] val;
            int sel = j_shift + j;
            if (has_clust[m] == 1) 
              val = clust_mat[, idx_clust[m,1]:idx_clust[m,2]] * 
                (eta_tmp .* y_Xq_data[idx_q[m,1]:idx_q[m,2], sel]);
            else val = eta_tmp .* y_Xq_data[idx_q[m,1]:idx_q[m,2], sel];
            mark = mark + 1;
            e_eta_q = e_eta_q + a_beta[mark] * val;
          }
        }
        mark3 = mark3 + 1; // count even if assoc type isn't used
        if (has_assoc[13,m] == 1) { # etavalue*etavalue
          for (j in 1:size_which_interactions[mark3]) { 
      	    int j_shift = (mark3 == 1) ? 0 : sum(size_which_interactions[1:(mark3-1)]);
            int sel = which_interactions[j+j_shift];
            vector[nrow_e_Xq] val;    
            vector[nrow_y_Xq[sel]] eta_tmp2;
            eta_tmp2 = y_eta_q[idx_q[sel,1]:idx_q[sel,2]];
            val = eta_tmp .* eta_tmp2;
    	      mark = mark + 1;
            e_eta_q = e_eta_q + a_beta[mark] * val;  
         }
        }
        mark3 = mark3 + 1; // count even if assoc type isn't used
        if (has_assoc[14,m] == 1) { # etavalue*muvalue
          for (j in 1:size_which_interactions[mark3]) { 
      	    int j_shift = (mark3 == 1) ? 0 : sum(size_which_interactions[1:(mark3-1)]);
            int sel = which_interactions[j+j_shift];
            vector[nrow_e_Xq] val;    
            vector[nrow_y_Xq[sel]] mu_tmp2;
            mu_tmp2 = evaluate_mu(y_eta_q[idx_q[sel,1]:idx_q[sel,2]], 
                                  family[sel], link[sel]);
            val = eta_tmp .* mu_tmp2;  	      
    	      mark = mark + 1;
            e_eta_q = e_eta_q + a_beta[mark] * val;  
          }
        }
        
        // add etaslope and any interactions  to event submodel eta
        mark2 = mark2 + 1;
        if ((has_assoc[2,m] == 1) || (has_assoc[10,m] == 1)) {
          vector[nrow_y_Xq[m]] dydt_eta_q;
          dydt_eta_q = (y_eta_q_eps[idx_q[m,1]:idx_q[m,2]] - eta_tmp) / eps;
          if (has_assoc[2,m] == 1) { # etaslope
            vector[nrow_e_Xq] val;    
            if (has_clust[m] == 1) 
              val = clust_mat[, idx_clust[m,1]:idx_clust[m,2]] * dydt_eta_q;
            else val = dydt_eta_q;          
            mark = mark + 1;
            e_eta_q = e_eta_q + a_beta[mark] * val;
          }
          if (has_assoc[10,m] == 1) { # etaslope*data
      	    int tmp = a_K_data[mark2];
      	    int j_shift = (mark2 == 1) ? 0 : sum(a_K_data[1:(mark2-1)]);
            for (j in 1:tmp) {
              vector[nrow_e_Xq] val;    
              int sel = j_shift + j;
              if (has_clust[m] == 1) 
                val = clust_mat[, idx_clust[m,1]:idx_clust[m,2]] * 
                  (dydt_eta_q .* y_Xq_data[idx_q[m,1]:idx_q[m,2], sel]);
              else val = dydt_eta_q .* y_Xq_data[idx_q[m,1]:idx_q[m,2], sel];            
              mark = mark + 1;
              e_eta_q = e_eta_q + a_beta[mark] * val;
            }    
          }         
        }
      }
          
      //----- etaauc
      
      // add etaauc to event submodel eta
      if (has_assoc[3,m] == 1) { # etaauc
        vector[nrow_y_Xq_auc[m]] y_eta_q_auc_tmp; # eta at all auc quadpoints (for submodel m)
        vector[nrow_y_Xq[m]] val; # eta following summation over auc quadpoints 
        y_eta_q_auc_tmp = y_eta_q_auc[idx_qauc[m,1]:idx_qauc[m,2]];
        mark = mark + 1;
        for (r in 1:nrow_y_Xq[m]) {
          vector[auc_quadnodes] val_tmp;
          vector[auc_quadnodes] wgt_tmp;
          val_tmp = y_eta_q_auc_tmp[((r-1) * auc_quadnodes + 1):(r * auc_quadnodes)];
          wgt_tmp = auc_quadweights[((r-1) * auc_quadnodes + 1):(r * auc_quadnodes)];
          val[r] = sum(wgt_tmp .* val_tmp);
        }
        e_eta_q = e_eta_q + a_beta[mark] * val;          
      }       
      
      //----- muvalue or muslope, and any interactions
      
      if (has_assoc[4,m]  == 1 || // muvalue
          has_assoc[11,m] == 1 || // muvalue * data
          has_assoc[15,m] == 1 || // muvalue * etavalue
          has_assoc[16,m] == 1 || // muvalue * muvalue 
          has_assoc[5,m]  == 1 || // muslope
          has_assoc[12,m] == 1) { // muslope * data
          
        // declare and define mu for submodel m  
        vector[nrow_y_Xq[m]] mu_tmp; 
        mu_tmp = evaluate_mu(y_eta_q[idx_q[m,1]:idx_q[m,2]],
                             family[m], link[m]);
                             
        // add muvalue and any interactions to event submodel eta   
        mark2 = mark2 + 1;
        if (has_assoc[4,m] == 1) { # muvalue
          vector[nrow_e_Xq] val;    
          if (has_clust[m] == 1) 
            val = clust_mat[, idx_clust[m,1]:idx_clust[m,2]] * mu_tmp;
          else val = mu_tmp;        
          mark = mark + 1;
          e_eta_q = e_eta_q + a_beta[mark] * val; 
        }
        if (has_assoc[11,m] == 1) { # muvalue*data
    	    int tmp = a_K_data[mark2]; 
    	    int j_shift = (mark2 == 1) ? 0 : sum(a_K_data[1:(mark2-1)]);
          for (j in 1:tmp) {
            vector[nrow_e_Xq] val;    
            int sel = j_shift + j;
            if (has_clust[m] == 1) 
              val = clust_mat[, idx_clust[m,1]:idx_clust[m,2]] *
                (mu_tmp .* y_Xq_data[idx_q[m,1]:idx_q[m,2], sel]);
            else val = mu_tmp .* y_Xq_data[idx_q[m,1]:idx_q[m,2], sel];              
            mark = mark + 1;
            e_eta_q = e_eta_q + a_beta[mark] * val;
          }      
        } 
        mark3 = mark3 + 1; // count even if assoc type isn't used
        if (has_assoc[15,m] == 1) { # muvalue*etavalue
          for (j in 1:size_which_interactions[mark3]) {
      	    int j_shift = (mark3 == 1) ? 0 : sum(size_which_interactions[1:(mark3-1)]);
            int sel = which_interactions[j+j_shift];
            vector[nrow_e_Xq] val;    
            vector[nrow_y_Xq[sel]] eta_tmp2;
            eta_tmp2 = y_eta_q[idx_q[sel,1]:idx_q[sel,2]];
            val = mu_tmp .* eta_tmp2;        	      
    	      mark = mark + 1;
            e_eta_q = e_eta_q + a_beta[mark] * val;  
         }
        }      
        mark3 = mark3 + 1; // count even if assoc type isn't used
        if (has_assoc[16,m] == 1) { # muvalue*muvalue
          for (j in 1:size_which_interactions[mark3]) { 
      	    int j_shift = (mark3 == 1) ? 0 : sum(size_which_interactions[1:(mark3-1)]);
      	    int sel = which_interactions[j+j_shift];
            vector[nrow_e_Xq] val;    
            vector[nrow_y_Xq[sel]] mu_tmp2;
            mu_tmp2 = evaluate_mu(y_eta_q[idx_q[sel,1]:idx_q[sel,2]],
                                  family[sel], link[sel]);
            val = mu_tmp .* mu_tmp2;        	      
    	      mark = mark + 1;
            e_eta_q = e_eta_q + a_beta[mark] * val;  
         }
        }      
        
        // declare and define slope of mu for submodel m
        if (has_assoc[5,m] == 1 || has_assoc[12,m] == 1) {
          vector[nrow_y_Xq[m]] mu_eps_tmp; 
          vector[nrow_y_Xq[m]] dydt_q;
          mu_eps_tmp = 
            evaluate_mu(y_eta_q_eps[idx_q[m,1]:idx_q[m,2]], family[m], link[m]);
          dydt_q = (mu_eps_tmp - mu_tmp) / eps;
          
          // add muslope and any interactions to event submodel eta
          mark2 = mark2 + 1;
          if (has_assoc[5,m] == 1) { # muslope
            vector[nrow_e_Xq] val;    
            if (has_clust[m] == 1) 
              val = clust_mat[, idx_clust[m,1]:idx_clust[m,2]] * dydt_q;
            else val = dydt_q;  
            mark = mark + 1;
            e_eta_q = e_eta_q + a_beta[mark] * val;          
          }
          if (has_assoc[12,m] == 1) { # muslope*data
      	    int tmp = a_K_data[mark2];
      	    int j_shift = (mark2 == 1) ? 0 : sum(a_K_data[1:(mark2-1)]);
            for (j in 1:tmp) {
              vector[nrow_e_Xq] val;    
              int sel = j_shift + j;
              if (has_clust[m] == 1) 
                val = clust_mat[, idx_clust[m,1]:idx_clust[m,2]] * 
                  (dydt_q .* y_Xq_data[idx_q[m,1]:idx_q[m,2], sel]);
              else val = dydt_q .* y_Xq_data[idx_q[m,1]:idx_q[m,2], sel];             
              mark = mark + 1;
              e_eta_q = e_eta_q + a_beta[mark] * val;
            }          
          } 
        }            
      }

      //----- muauc

      // add muauc to event submodel eta
      if (has_assoc[6,m] == 1) { # muauc
        vector[nrow_y_Xq_auc[m]] y_q_auc_tmp; # mu at all auc quadpoints (for submodel m)  
        vector[nrow_y_Xq[m]] val; # mu following summation over auc quadpoints 
        y_q_auc_tmp = 
          evaluate_mu(y_eta_q_auc[idx_qauc[m,1]:idx_qauc[m,2]], 
                      family[m], link[m]);
        mark = mark + 1;
        for (r in 1:nrow_y_Xq[m]) {
          vector[auc_quadnodes] val_tmp;
          vector[auc_quadnodes] wgt_tmp;
          val_tmp = y_q_auc_tmp[((r-1) * auc_quadnodes + 1):(r * auc_quadnodes)];
          wgt_tmp = auc_quadweights[((r-1) * auc_quadnodes + 1):(r * auc_quadnodes)];
          val[r] = sum(wgt_tmp .* val_tmp);
        }
        e_eta_q = e_eta_q + a_beta[mark] * val;          
      }  

    }
    
    //-----  shared random effects
    
  	if (sum_size_which_b > 0) {
  	  int mark_beg;  // used to define segment of a_beta
  	  int mark_end;
  	  matrix[nrow_e_Xq,sum_size_which_b] x_assoc_shared_b;	  
      mark_beg = mark + 1;	  
  	  mark_end = mark + sum_size_which_b;
  	  x_assoc_shared_b = make_x_assoc_shared_b(
  	    b_not_by_model, l, p, pmat, Npat, quadnodes, which_b_zindex,
  	    sum_size_which_b, size_which_b, t_i, M);
  	  e_eta_q = e_eta_q + x_assoc_shared_b * a_beta[mark_beg:mark_end];
  	  mark = mark + sum_size_which_b;
    }	
  	if (sum_size_which_coef > 0) {
  	  int mark_beg;  // used to define segment of a_beta
  	  int mark_end;
  	  matrix[nrow_e_Xq,sum_size_which_coef] x_assoc_shared_coef;	  
      mark_beg = mark + 1;	  
  	  mark_end = mark + sum_size_which_coef;
  	  x_assoc_shared_coef = make_x_assoc_shared_coef(
  	    b_not_by_model, beta, KM, M, t_i, l, p, pmat, Npat, quadnodes,
  	    sum_size_which_coef, size_which_coef,
  	    which_coef_zindex, which_coef_xindex,
  	    has_intercept, has_intercept_nob,
  	    has_intercept_lob, has_intercept_upb,
  	    gamma_nob, gamma_lob, gamma_upb);
  	  e_eta_q = e_eta_q + x_assoc_shared_coef * a_beta[mark_beg:mark_end];
  	  mark = mark + sum_size_which_coef;
    }    
