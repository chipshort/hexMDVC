package hex.mdvc.log;

import haxe.macro.Context;
import haxe.macro.Expr;
import hex.error.PrivateConstructorException;

/**
 * ...
 * @author Francis Bourre
 */
class LoggableBuilder
{
	public static inline var DebugAnnotation 	= "Debug";
	public static inline var InfoAnnotation 	= "Info";
	public static inline var WarnAnnotation 	= "Warn";
	public static inline var ErrorAnnotation 	= "Error";
	public static inline var FatalAnnotation 	= "Fatal";
	
	/** @private */
    function new()
    {
        throw new PrivateConstructorException( "This class can't be instantiated." );
    }
	
	macro static public function build() : Array<Field> 
	{
		var fields = Context.getBuildFields();
		
		if ( Context.getLocalClass().get().isInterface )
		{
			return fields;
		}
		
		var className = Context.getLocalClass().get().module;
		var loggerAnnotations = [ DebugAnnotation, InfoAnnotation, WarnAnnotation, ErrorAnnotation, FatalAnnotation ];

		for ( f in fields )
		{
			switch( f.kind )
			{ 
				//TODO exclude constructor
				//TODO add class metadata that adds the injected logger property 
				//TODO make unit tests
				case FFun( func ):
					
					var meta = f.meta.filter( function ( m ) { return loggerAnnotations.indexOf( m.name ) != -1; } );
					var isLoggable = meta.length > 0;
					if ( isLoggable ) 
					{
						#if debug
						var expressions = [ macro @:mergeBlock {} ];
						var methArgs = [ for ( arg in func.args ) macro @:pos(f.pos) $i { arg.name } ];
						var debugArgs = [ macro @:pos(f.pos) $v { className + '::' + f.name } ].concat( methArgs );
						var methodName = meta[ 0 ].name.toLowerCase();
						
						var body = macro @:pos(f.pos) @:mergeBlock
						{
							#if debug
							logger.$methodName( [$a { debugArgs } ] );
							#end
						};

						expressions.push( body );
						expressions.push( func.expr );
						func.expr = macro @:pos(f.pos) $b { expressions };
						#end
						
						f.meta = [ meta[ 0 ] ];//TODO Check everything is fine
					}
					
				case _:
			}
			
		}
		
		return fields;
	}
}