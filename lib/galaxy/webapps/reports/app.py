import config
import sys
import time

import galaxy.model
from galaxy.web import security


class UniverseApplication( object ):
    """Encapsulates the state of a Universe application"""
    def __init__( self, **kwargs ):
        print >> sys.stderr, "python path is: " + ", ".join( sys.path )
        self.name = "reports"
        # Read config file and check for errors
        self.config = config.Configuration( **kwargs )
        self.config.check()
        config.configure_logging( self.config )
        # Determine the database url
        if self.config.database_connection:
            db_url = self.config.database_connection
        else:
            db_url = "sqlite:///%s?isolation_level=IMMEDIATE" % self.config.database
        # Setup the database engine and ORM
        self.model = galaxy.model.mapping.init( self.config.file_path,
                                                db_url,
                                                self.config.database_engine_options,
                                                create_tables=True )
        self.targets_mysql = 'mysql' in self.config.database_connection
        # Security helper
        self.security = security.SecurityHelper( id_secret=self.config.id_secret )
        # used for cachebusting -- refactor this into a *SINGLE* UniverseApplication base.
        self.server_starttime = int(time.time())

    def shutdown( self ):
        pass
