enum {//request enums
	MABStopApplication = 1,
	MABContApplication,
	MABKillApplication,
	MABApplicationSetPriority,
	MABApplicationGetCpu,
	MABQuitTool
};

enum {//response enums
	MABToolSuccess = 1,
	MABToolFailure = 0
};

struct toolRequest {
	int requestType; //one of the request enums
	int pid;
	int otherInfo;	//the priority value in most cases
};

struct toolResponse {
	int responseType; //one of the response enums
	int otherInfo;
};

#define CPU_PRECISION (10000.0F)

struct toolResponse ExecuteCommand(struct toolRequest);
