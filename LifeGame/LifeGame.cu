#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define WIDTH 512
#define HEIGHT 512

#define DEAD '-'
#define LIVE '*'
#define NONE '+'

int main(int argc, char** argv) {
	if (argc < 2) {
		perror("parameter more than 1");
		exit(1);
	}

	char width = WIDTH;
	char height = HEIGHT;
	int turnLimit = 500;
	int turn = 0;

	char* gamefieldParallelHost;

	srand((unsigned)time(NULL));
	
	for (int i = 0; i < width * height; i++) {
		gamefieldParallelHost[i] = rand() % 2;
	}

	for (int i = 0; i < width; i++) {
		gamefieldParallelHost[i] = NONE;
		gamefieldParallelHost[i + width * (height - 1)] = NONE;
	}

	for (int i = 0; i < height; i++) {
		gamefieldParallelHost[0 + width * i] = NONE; 
		gamefieldParallelHost[width - 1 + width * i] = NONE;
	}

	for (int i = 0; i < height; i++) {
		gamefieldParallelHost[0 + width * i] = NONE; 
		gamefieldParallelHost[width - 1 + width * i] = NONE; 
	}

	for (int i = 0; i < turnLimit; i++) {

	}
       
	return 0;
}