package social.fb {
	/**
	 * VO to hold multiple queries for use in Facebook.fqlMultiQuery
	 *
	 */
	public class FqlMultiQuery {
		
		/**
		 * Hash of query strings, indexed by query name 
		 */		
		public var queries:Object;
		
		/**
		 * Creates a new FQLMultiQuery.
		 *
		 */
		public function FqlMultiQuery() {
			queries = {};
		}
		
		/**
		 * Adds a new query. Throws an error if there are duplicate query names
		 *  
		 * @param query String The query string to execute
		 * @param name String The name of the query
		 * @param values Object Replaces string values in the in the query. 
		 * ie. Replaces {digit} or {id} with the corresponding key-value in the object
		 * 
		 */		
		public function add(query:String, name:String, values:Object = null):void {			
			if (queries.hasOwnProperty(name)) { throw new Error("Query name already exists, there cannot be duplicate names"); }
			
			for (var n:String in values) {
				query = query.replace(new RegExp('\\{'+n+'\\}', 'g'), values[n]);
			}
			
			queries[name] = query;
		}
		
		/**
		 * 
		 * @return String The JSON encoded value of the queries object
		 * 
		 */		
		public function toString():String {
			return JSON.stringify(queries);			
		}
	}
}