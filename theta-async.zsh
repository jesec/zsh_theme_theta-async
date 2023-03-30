#!/usr/bin/env zsh

THETA_COLOR_VCS=33
THETA_COLOR_SSH=226
THETA_COLOR_DIR=67
THETA_COLOR_ERROR=208
THETA_COLOR_REV=80
THETA_COLOR_BR=157
THETA_COLOR_DIRTY=208
THETA_COLOR_LR=220
THETA_COLOR_THETA=42

prompt_theta_ssh_st(){ [[ -n "$SSH_CLIENT" ]] && echo -n "[S] "; }

prompt_theta_fishy_collapsed_wd() {
  echo $(pwd | perl -pe '
   BEGIN {
      binmode STDIN,  ":encoding(UTF-8)";
      binmode STDOUT, ":encoding(UTF-8)";
   }; s|^$ENV{HOME}|~|g; s|/([^/.])[^/]*(?=/)|/$1|g; s|/\.([^/])[^/]*(?=/)|/.$1|g
')
}

# Git
prompt_theta_is_git(){ if [[ $(git branch 2>/dev/null) != "" ]]; then; echo 1 ; else; echo 0 ; fi; }

prompt_theta_async_git_branch(){ ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="detached" || return false; echo -n ${ref#refs/heads/}; return true; }
prompt_theta_async_git_rev(){ rev=$(git rev-parse HEAD | cut -c 1-7); echo -n "${rev}"; return true; }
prompt_theta_async_git_head_commit(){ re=$(git log --pretty=format:"%s" -1 2> /dev/null); echo -n "${re}"; return true; }

prompt_theta_async_git_dirty(){
  local theta_git_status=`git status --porcelain 2>/dev/null`
  _mod=$(echo ${theta_git_status} | grep 'M ' | wc -l | tr -d ' ');
  _add=$(echo ${theta_git_status} | grep 'A ' | wc -l | tr -d ' ');
  _del=$(echo ${theta_git_status} | grep 'D ' | wc -l | tr -d ' ');
  _new=$(echo ${theta_git_status} | grep '?? ' | wc -l | tr -d ' ');
  [[ "$_mod" != "0" ]] && echo -n " ⭑";
  [[ "$_add" != "0" ]] && echo -n " +";
  [[ "$_del" != "0" ]] && echo -n " -";
  [[ "$_new" != "0" ]] && echo -n " ?";
}

prompt_theta_async_git_left_right(){
  if [[ $(prompt_theta_async_git_branch) != "detached" ]]; then
    _pull=$(git rev-list --left-right --count `prompt_theta_async_git_branch`...origin/`prompt_theta_async_git_branch` 2>/dev/null | awk '{print $2}' | tr -d ' \n');
    _push=$(git rev-list --left-right --count `prompt_theta_async_git_branch`...origin/`prompt_theta_async_git_branch` 2>/dev/null | awk '{print $1}' | tr -d ' \n');
    [[ "$_pull" != "0" ]] && [[ "$_pull" != "" ]] && echo -n " ▼";
    [[ "$_push" != "0" ]] && [[ "$_push" != "" ]] && echo -n " ▲";
  else
    echo -n "";
  fi
}

# Sapling
prompt_theta_is_sl(){ if [[ $(sl whereami 2>/dev/null) != "" ]]; then; echo 1 ; else; echo 0 ; fi; }

prompt_theta_async_sl_rev(){ rev=$(sl whereami | cut -c 1-10); echo -n "${rev}"; return true; }
prompt_theta_async_sl_head_commit(){ re=$(sl log --template '{desc|firstline}' -r . 2> /dev/null); echo -n "${re}"; return true; }

prompt_theta_async_sl_dirty(){
  local theta_sl_status=`sl st 2>/dev/null`
  _mod=$(echo ${theta_sl_status} | grep 'M ' | wc -l | tr -d ' ');
  _add=$(echo ${theta_sl_status} | grep 'A ' | wc -l | tr -d ' ');
  _del=$(echo ${theta_sl_status} | grep 'R ' | wc -l | tr -d ' ');
  _mis=$(echo ${theta_sl_status} | grep '! ' | wc -l | tr -d ' ');
  _new=$(echo ${theta_sl_status} | grep '? ' | wc -l | tr -d ' ');
  [[ "$_mod" != "0" ]] && echo -n " ⭑";
  [[ "$_add" != "0" ]] && echo -n " +";
  [[ "$_del" != "0" ]] && echo -n " -";
  [[ "$_mis" != "0" ]] && echo -n " !";
  [[ "$_new" != "0" ]] && echo -n " ?";
}

prompt_theta_async_vcs_info(){
  if [[ $(prompt_theta_is_git) == 1 ]]; then
    local vcs_branch="%F{$THETA_COLOR_VCS}G%f %F{$THETA_COLOR_BR}`prompt_theta_async_git_branch`%f"
    local vcs_left_right="%F{$THETA_COLOR_LR}`prompt_theta_async_git_left_right`%f"
    local vcs_rev="%F{$THETA_COLOR_REV}`prompt_theta_async_git_rev`%f"
    local vcs_dirty="%F{$THETA_COLOR_DIRTY}`prompt_theta_async_git_dirty`%f"
    print " [$vcs_branch$vcs_left_right $vcs_rev$vcs_dirty] [`prompt_theta_async_git_head_commit`]"
  elif [[ $(prompt_theta_is_sl) == 1 ]]; then
    local vcs_branch="%F{$THETA_COLOR_VCS}H%f"
    local vcs_rev="%F{$THETA_COLOR_REV}`prompt_theta_async_sl_rev`%f"
    local vcs_dirty="%F{$THETA_COLOR_DIRTY}`prompt_theta_async_sl_dirty`%f"
    print " [$vcs_branch$vcs_left_right $vcs_rev$vcs_dirty] [`prompt_theta_async_sl_head_commit`]"
  fi
}

prompt_theta_preprompt_render() {
  local vcs_info=$3
  PROMPT='
 %F{$THETA_COLOR_DIR}[$(prompt_theta_fishy_collapsed_wd)]%f${vcs_info}
 %F{$THETA_COLOR_SSH}`prompt_theta_ssh_st`%f%(?.%F{$THETA_COLOR_THETA}Θ %f.%F{$THETA_COLOR_ERROR}Θ %f)'
  zle && zle .reset-prompt
  async_stop_worker prompt_theta -n
}

prompt_theta_async_tasks() {
  async_start_worker "prompt_theta" -u -n
  async_register_callback "prompt_theta" prompt_theta_preprompt_render
  async_job "prompt_theta" prompt_theta_async_vcs_info
}

prompt_theta_precmd() {
  prompt_theta_async_tasks

  PROMPT='
 %F{$THETA_COLOR_DIR}[%~]%f
 %F{$THETA_COLOR_SSH}`prompt_theta_ssh_st`%f%(?.%F{$THETA_COLOR_THETA}Θ %f.%F{$THETA_COLOR_ERROR}Θ %f)'
  RPROMPT=''
}

prompt_theta_setup() {
  zmodload zsh/zle
  zmodload zsh/parameter

  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info
  autoload -Uz 256color
  autoload -Uz async && async

  add-zsh-hook precmd prompt_theta_precmd
}

prompt_theta_setup "$@"
