#pragma once
#include <utility>

// Vien's
std::pair<int, int> get_best_corn(int x, int y, int **k);
int compute_time_to_point(int x0, int y0, int x1, int y1);
int bonk_handler(int direction);
bool should_solve_puzzle(int eta);
bool should_pickup(int x, int y);

// Tino's
void compute_direction(int x0, int y0, int x1, int y1);
void build_silo(int x, int y);
void travel_to_point(int x, int y);
void send_mb_to_point(int x, int y);
std::pair<int, int> compute_silo_xy();
