/*
 *  ASArraySorting.h
 *  App Stop
 *
 *  Created by Michael Bianco on 12/9/06.
 *  Copyright 2006 Prosit Software. All rights reserved.
 *
 */

#import <stdbool.h>

void insertInt(int sortedArray[], int length, int new);
void selectionSort(int array[], int length);
void arrayComparison(int *left, int *right, int *leftDiff, int *rightDiff, int resultLengths[]);
int binarySearch(int sortedArray[], int length, int target);
bool containsInt(int sortedArray[], int length, int target);