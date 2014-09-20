/*
 *  ASArraySorting.c
 *  App Stop
 *
 *  Created by Michael Bianco on 12/9/06.
 *  Copyright 2006 Prosit Software. All rights reserved.
 *
 */

#include "ASArraySorting.h"

#import <stdio.h>

void insertInt(int sortedArray[], int length, int new) {
	int i = length - 1;
	
	while (i >= 0 && sortedArray[i] > new) {
		sortedArray[i + 1] = sortedArray[i];
		i--;
	}
	
	sortedArray[i + 1] = new;		
}

void selectionSort(int array[], int length) {
	int i, j, min, minat, temp;
	
	for(i = 0; i < (length - 1); i++) {
		minat = i;
		min = array[i];
		
		for(j = i + 1; j < (length); j++) {//select the min of the rest of array
			if(min > array[j]) {//ascending order for descending reverse
				minat = j;  //the position of the min element 
				min = array[j];
			}
		}
		
		temp = array[i];
		array[i] = array[minat];
		array[minat] = temp;
	}
}

void arrayComparison(int *left, int *right, int *leftDiff, int *rightDiff, int resultLengths[]) {
	/*
	 compare two lists of integers. Both lists must end with a -1.
	 leftDiff & rightDiff must be length of MAX(left, right)
	
	 */
	
	int *leftPtr = left, *rightPtr = right;
	int *leftDiffPtr = leftDiff, *rightDiffPtr = rightDiff;
	
	while(*leftPtr != -1 || *rightPtr != -1) {
		
		// Check to see if one of the arrays is out of bounds
		if(*leftPtr == -1) {
			// then everything in the right array from here on is different
			*rightDiffPtr++ = *rightPtr++;
			continue;
		} else if(*rightPtr == -1) {
			// then everything in the left array from here on is different
			*leftDiffPtr++ = *leftPtr++;
			continue;
		}
		
		//NSLog(@"Compare %i : %i", *allProcsPtr, *storedProcsPtr);
		
		// Compare current index
		if(*leftPtr == *rightPtr) {
			*leftPtr++, *rightPtr++;
		} else {// values are not equal
			if(*leftPtr > *rightPtr) {
				// then the current stored apps is closed
				*rightDiffPtr++ = *rightPtr++;
			} else if(*leftPtr < *rightPtr) {
				// then the current allProcsPtr is open
				*leftDiffPtr++ = *leftPtr++;
			} else {
				printf("Uncaught!");
			}
		}
	}
	
	// compute the length
	resultLengths[0] = leftDiffPtr - leftDiff;
	resultLengths[1] = rightDiffPtr - rightDiff;
		
	// mark the ends of the array
	*leftDiffPtr = -1, *rightDiffPtr = -1;
}

int binarySearch(int sortedArray[], int length, int target) {
	
}

bool containsInt(int sortedArray[], int length, int target) {
	
}