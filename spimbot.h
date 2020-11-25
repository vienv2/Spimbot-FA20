#pragma once
#include <utility>

// Vien's
std::pair<char, char> get_best_corn(char x, char y, char **k);
char compute_time_to_point(char x0, char y0, char x1, char y1);
char bonk_handler(char direction);
bool should_solve_puzzle();

// Tino's
void compute_direction(char x0, char y0, char x1, char y1);
void build_silo(char x, char y);
void travel_to_point(char x, char y);
void send_mb_to_point();
std::pair<char, char> compute_silo_xy();
