#include <ilopl/iloopl.h>
#include <vector>

using namespace std;

int main() {
	IloEnv env;
	try {
		IloOplErrorHandler handler(env, cout);
		IloOplModelSource model(env, "path\\to\\file\\projekt.mod"); //Need to edit
		IloOplSettings settings(env, handler);
		settings.setWithWarnings(IloFalse);
		IloOplModelDefinition def(model, settings);
		IloCplex cplex(env);
		IloOplModel opl(def, cplex);
		IloOplDataSource data(env, "path\\to\\file\\projekt.dat");  //Need to edit
		
		opl.addDataSource(data);
		opl.generate();
		if (cplex.solve()) {
			cout << endl
				<< "OBJECTIVE: " << fixed << setprecision(2) << opl.getCplex().getObjValue()
				<< endl;
			opl.postProcess();
			opl.printSolution(cout);
			cplex.writeSolution("path\\to\\file\\rozwiazanie.sol");  //Need to edit
		}
		else {
			cout << "No solution!" << endl;
			return 404;
		}
		cout << "///////////" << endl;
		cout << "WARM START" << endl;
		cout << "///////////" << endl;
		IloOplCplexVectors warmStartVectors = IloOplCplexVectors(env);
		IloCplex cplexWarmStart(env);
		IloOplModel oplWarmStart(def, cplexWarmStart);
		oplWarmStart.addDataSource(data);
		oplWarmStart.generate();
		
		vector<const char *> decisionVariables = {
				"CapAdd",
				"Profit",
				"HeifSell",
				"CowTotal",
				"Cow",
				"SmallCow",
				"GrainGrow",
				"GrainSell",
				"GrowBuy",
				"SugarbeetSell",
				"SugarbeetBuy",
				"SugarbeetGrow",
				"LaborYear"
		};
		vector<const char*>::iterator it;
		vector<IloNumVarMap> numVarMap;
		vector<IloNumVarMap>::iterator itVarMap;
		vector<IloNumMap> numMap;
		vector<IloNumMap>::iterator itMap;

		for (it = decisionVariables.begin(); it != decisionVariables.end(); it++) {
			IloOplElement element = opl.getElement(*it);
			numVarMap.push_back(element.asNumVarMap());
			numMap.push_back(element.asNumMap());
		}
		
		for (itVarMap = numVarMap.begin(), itMap = numMap.begin(); itVarMap != numVarMap.end(); itVarMap++, itMap++) {
			warmStartVectors.attach(*itVarMap, *itMap);
		}

		warmStartVectors.setStart(cplexWarmStart);

		if (cplexWarmStart.solve()) {
			cout << endl
				<< "OBJECTIVE: " << fixed << setprecision(2) << oplWarmStart.getCplex().getObjValue()
				<< endl;
			oplWarmStart.postProcess();
			oplWarmStart.printSolution(cout);
		}
		else {
			cout << "No solution!" << endl;
			return 404;
		}
	}
	catch (exception e) {
		cout << "Jakis blad" << endl;
		return 500;
	}
	return 0;
}
