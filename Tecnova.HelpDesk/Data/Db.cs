using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;

namespace Tecnova.HelpDesk.Data
{
    public static class Db
    {
        public static SqlConnection Open()
        {
            var connection = new SqlConnection(ConfigurationManager.ConnectionStrings["Tecnova"].ConnectionString);
            connection.Open();
            return connection;
        }
        public static SqlParameter P(string name, object value)
        {
            return new SqlParameter(name, value ?? DBNull.Value);
        }
        public static DataTable Query(string sql, params SqlParameter[] args)
        {
            using (var connection = Open())
            using (var command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddRange(args);
                using (var adapter = new SqlDataAdapter(command))
                {
                    var table = new DataTable();
                    adapter.Fill(table);
                    return table;
                }
            }
        }
        public static int Execute(string sql, params SqlParameter[] args)
        {
            using (var connection = Open())
            using (var command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddRange(args);
                return command.ExecuteNonQuery();
            }
        }
        public static List<Dictionary<string,object>> Rows(DataTable table)
        {
            var rows = new List<Dictionary<string,object>>();
            foreach (DataRow row in table.Rows)
            {
                var item = new Dictionary<string,object>();
                foreach (DataColumn column in table.Columns)
                {
                    object value = row[column];
                    if (value == DBNull.Value) value = null;
                    else if (value is DateTime) value = ((DateTime)value).ToString("yyyy-MM-ddTHH:mm:ss.fffZ");
                    else if (value is byte[]) value = Convert.ToBase64String((byte[])value);
                    item[column.ColumnName] = value;
                }
                rows.Add(item);
            }
            return rows;
        }
    }
}
