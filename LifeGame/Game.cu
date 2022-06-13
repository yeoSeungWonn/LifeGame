#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "DS_timer.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <windows.h>


#define ROW 256
#define COL 256

#define NONE -1
#define DEAD 0
#define LIVE 1


void initfield(int* _gamefield1, int* _gamefield2);
void draw(int* _gamefield);
int checkMatrix(int* _gamefield1, int* _gamefield2);

__global__ void game(int* gamefieldOriginal, int* gamefieldBuffer)
{
	int width = blockDim.x;
	int height = gridDim.x;
	int blockID = threadIdx.x;

	int gridID = blockDim.x * blockIdx.x + blockID;
	

	if (gamefieldOriginal[gridID] == NONE) {
		gamefieldBuffer[gridID] = NONE;
	}
	else {
		int neighbors = 0;
		if (gamefieldOriginal[gridID - width - 1] == LIVE) { // upper left.
			neighbors++;
		}
		if (gamefieldOriginal[gridID - width] == LIVE) { // upper.
			neighbors++;
		}
		if (gamefieldOriginal[gridID - width + 1] == LIVE) { // upper right.
			neighbors++;
		}
		if (gamefieldOriginal[gridID - 1] == LIVE) { // left.
			neighbors++;
		}
		if (gamefieldOriginal[gridID + 1] == LIVE) { // right.
			neighbors++;
		}
		if (gamefieldOriginal[gridID + width - 1] == LIVE) { // lower left.
			neighbors++;
		}
		if (gamefieldOriginal[gridID + width] == LIVE) { // lower.
			neighbors++;
		}
		if (gamefieldOriginal[gridID + width + 1] == LIVE) { // lower right.
			neighbors++;
		}

		if (gamefieldOriginal[gridID] == DEAD) {
			if (neighbors == 3) {
				gamefieldBuffer[gridID] = LIVE;
			}
		}
		else if (gamefieldOriginal[gridID] == LIVE) {
			if (neighbors < 2 || neighbors > 3) {
				gamefieldBuffer[gridID] = DEAD;
			}
		}
	}
}

__global__ void copy(int* gamefieldOriginal, int* gamefieldBuffer) {
	int width = blockDim.x;
	int height = gridDim.x;
	int blockID = threadIdx.x;

	int gridID = blockDim.x * blockIdx.x + blockID;
	gamefieldOriginal[gridID] = gamefieldBuffer[gridID];

}

int main()
{
	DS_timer timer(2);
	timer.setTimerName(0, "CUDA Total");
	timer.setTimerName(1, "CPU Total");
	timer.initTimers();

	srand(time(NULL));
	int width = COL;
	int height = ROW;

	int size = sizeof(int) * width * height;

	int* gamefield;
	int term = 500;
	int count = 0;

	printf("%d * %d, %d games", ROW, COL, term);

	int* gamefieldParallelHost;
	int* gamefieldParallelCUDA;
	int* gamefieldBufferCUDA;
	int* gamefieldSerialHost;
	int* gamefieldBufferHost;

	cudaMalloc(&gamefieldParallelCUDA, size);
	cudaMalloc(&gamefieldBufferCUDA, size);

	gamefieldParallelHost = new int[width * height];
	gamefieldSerialHost = new int[width * height];
	gamefieldBufferHost = new int[width * height];

	memset(gamefieldParallelHost, 0, size);
	memset(gamefieldSerialHost, 0, size);
	memset(gamefieldBufferHost, 0, size);

	initfield(gamefieldParallelHost, gamefieldSerialHost);

	dim3 dimBlock(width);
	dim3 dimGrid(height);

	timer.onTimer(0);
	cudaMemcpy(gamefieldBufferCUDA, gamefieldParallelHost, size, cudaMemcpyHostToDevice);
	cudaMemcpy(gamefieldParallelCUDA, gamefieldParallelHost, size, cudaMemcpyHostToDevice);

	while (count < term)
	{

		game << <dimGrid, dimBlock >> > (gamefieldParallelCUDA, gamefieldBufferCUDA);
		copy << <dimGrid, dimBlock >> > (gamefieldParallelCUDA, gamefieldBufferCUDA);
		count++;
	}
	cudaDeviceSynchronize();
	cudaMemcpy(gamefieldParallelHost, gamefieldParallelCUDA, size, cudaMemcpyDeviceToHost);
	timer.offTimer(0);

	count = 0;
	timer.onTimer(1);
	memcpy(gamefieldBufferHost, gamefieldSerialHost, size);

	while (count < term) {
		for (int i = 0; i < ROW * COL; i++) {
			if (gamefieldSerialHost[i] == NONE) {
				gamefieldBufferHost[i] = NONE;
			}
			else {
				int neighbors = 0;
				if (gamefieldSerialHost[i - width - 1] == LIVE) { // upper left.
					neighbors++;
				}
				if (gamefieldSerialHost[i - width] == LIVE) { // upper.
					neighbors++;
				}
				if (gamefieldSerialHost[i - width + 1] == LIVE) { // upper right.
					neighbors++;
				}
				if (gamefieldSerialHost[i - 1] == LIVE) { // left.
					neighbors++;
				}
				if (gamefieldSerialHost[i + 1] == LIVE) { // right.
					neighbors++;
				}
				if (gamefieldSerialHost[i + width - 1] == LIVE) { // lower left.
					neighbors++;
				}
				if (gamefieldSerialHost[i + width] == LIVE) { // lower.
					neighbors++;
				}
				if (gamefieldSerialHost[i + width + 1] == LIVE) { // lower right.
					neighbors++;
				}

				if (gamefieldSerialHost[i] == DEAD) {
					if (neighbors == 3) {
						gamefieldBufferHost[i] = LIVE;
					}
				}
				else if (gamefieldSerialHost[i] == LIVE) {
					if (neighbors < 2 || neighbors > 3) {
						gamefieldBufferHost[i] = DEAD;
					}
				}
			}
			
		}
		memcpy(gamefieldSerialHost, gamefieldBufferHost, size);
		count++;
	}
	timer.offTimer(1);
	timer.printTimer();

	if (checkMatrix(gamefieldParallelHost, gamefieldSerialHost)) {
		printf("같다\n");
	}
	else
		printf("다르다");

	cudaFree(gamefieldParallelCUDA);
	cudaFree(gamefieldBufferCUDA);
	
	delete[] gamefieldParallelHost; delete[] gamefieldSerialHost; delete[] gamefieldBufferHost;

	return 0;
}

void initfield(int* _gamefield1, int* _gamefield2)
{
	for (int i = 0; i < ROW * COL; i++)
		_gamefield1[i] = rand() % 2;

	for (int i = 0; i < COL; i++)
	{
		_gamefield1[i] = NONE; // 맨 위
		_gamefield1[i + COL * (ROW - 1)] = NONE; // 맨 아래
	}

	for (int i = 0; i < ROW; i++)
	{
		_gamefield1[COL * i] = NONE; // 맨 왼쪽
		_gamefield1[COL * (i + 1) - 1] = NONE; // 맨 오른쪽
	}

	for (int i = 0; i < ROW * COL; i++) {
		_gamefield2[i] = _gamefield1[i];
	}
}

void draw(int* _gamefield)
{
	for (int i = 0; i < ROW; i++)
	{
		for (int j = 0; j < COL; j++)
		{
			printf("[%2d]", _gamefield[i * ROW + j]);
		}
		printf("\n");
	}
}


int checkMatrix(int* _gamefield1, int* _gamefield2) {
	for (int i = 0; i < ROW * COL; i++) {
		if (_gamefield1[i] != _gamefield2[i]) {
			return 0;
		}
	}
	return 1;
}
